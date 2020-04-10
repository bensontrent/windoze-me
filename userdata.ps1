
function Set-Password
## Changes a system user's password.
{
  Param
  (
    [Parameter(Mandatory=$true)][string]$User,
    [Parameter(Mandatory=$true)][string]$Pass
  )
  $Admin = [adsi]("WinNT://./$User, user")
  If ($Admin.Name)
  {
    $Admin.psbase.invoke("SetPassword", $Pass)
  }

}

function Install-PythonGit
## Use the Watchmaker bootstrap to install Python and Git.
{
  $BootstrapUrl = "${bootstrap_url}"
  $PythonUrl = "${python_url}"
  $GitUrl = "${git_url}"

  # Download bootstrap file
  $BootstrapFile = "$${Env:Temp}\$($${BootstrapUrl}.split("/")[-1])"
  (New-Object System.Net.WebClient).DownloadFile($BootstrapUrl, $BootstrapFile)

  # Install python and git
  & "$BootstrapFile" `
      -PythonUrl "$PythonUrl" `
      -GitUrl "$GitUrl" `
      -Verbose -ErrorAction Stop
}

function Install-7Zip
{
  (New-Object System.Net.WebClient).DownloadFile("${sevenzip_url}", "${temp_dir}\7z-install.exe")
  Invoke-Expression -Command "${temp_dir}\7z-install.exe /S /D='C:\Program Files\7-Zip'" -ErrorAction Continue
}

function Setup-Protocols
{
  # Use TLS, as git won't do SSL now
  [Net.ServicePointManager]::SecurityProtocol = "Ssl3, Tls, Tls11, Tls12"
}

Set-Password -User "Administrator" -Pass "${passwd}"

Setup-Protocols
mkdir ${temp_dir}
Install-PythonGit
Install-7Zip
