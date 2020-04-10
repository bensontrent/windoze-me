locals {
  # plus3, amazon, and ubuntu canonical
  ami_owners    = ["701759196663", "099720109477", "801119661308"]
  sevenzip_url  = "https://www.7-zip.org/a/7z1900-x64.exe"
  bootstrap_url = "https://raw.githubusercontent.com/plus3it/watchmaker/develop/docs/files/bootstrap/watchmaker-bootstrap.ps1"
  git_url       = "https://github.com/git-for-windows/git/releases/download/v2.26.0.windows.1/Git-2.26.0-64-bit.exe"
  python_url    = "https://www.python.org/ftp/python/3.6.8/python-3.6.8-amd64.exe"
  temp_dir      = "C:\\Temp"
}

#used just to find the ami id matching criteria, which is then used in provisioning resource
data "aws_ami" "find_ami" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base*"]
  }

  owners = local.ami_owners
}

# Subnet for instances
resource "aws_default_subnet" "windoze" {
  availability_zone = var.availability_zone
}

data "aws_subnet" "windoze" {
  id = var.subnet_id == "" ? aws_default_subnet.windoze.id : var.subnet_id
}

# Used to get local ip for security group ingress
data "http" "ip" {
  url = "http://ipv4.icanhazip.com"
}

# used for importing the key pair created using aws cli
resource "aws_key_pair" "auth" {
  key_name   = "${var.identifier}-key"
  public_key = tls_private_key.gen_key.public_key_openssh
}

resource "tls_private_key" "gen_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "random_string" "password" {
  length           = 18
  special          = true
  override_special = "()~!@#^*+=|{}[]:;,?"
}

# Security group to access the instances over WinRM
resource "aws_security_group" "sg" {
  name        = "${var.identifier}-sg"
  description = "Used in windoze-me"
  vpc_id      = data.aws_subnet.windoze.vpc_id

  tags = {
    Name = var.identifier
  }

  # SSH access from anywhere
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.ip.body)}/32"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# bread & butter - provision/create windows instance
resource "aws_instance" "win" {
  ami                         = data.aws_ami.find_ami.id
  associate_public_ip_address = var.assign_public_ip
  iam_instance_profile        = var.instance_profile
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.auth.id
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  user_data                   = <<-HEREDOC
    <powershell>
    ${data.template_file.userdata.rendered}
    </powershell>
    HEREDOC


  tags = {
    Name = var.identifier
  }

  timeouts {
    create = "50m"
  }

}

data "template_file" "userdata" {
  template = file("userdata.ps1")

  vars = {
    sevenzip_url  = local.sevenzip_url
    bootstrap_url = local.bootstrap_url
    git_url       = local.git_url
    python_url    = local.python_url
    passwd        = random_string.password.result
    temp_dir      = local.temp_dir
  }
}
