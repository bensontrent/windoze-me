output "ami_id" {
  value = data.aws_ami.find_ami.id
}

output "winrm_pass" {
  value = random_string.password.result
}

output "private_key" {
  value = tls_private_key.gen_key.private_key_pem
}

output "public_key" {
  value = tls_private_key.gen_key.public_key_openssh
}
