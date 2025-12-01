<#PSScriptInfo
.VERSION      0.1.0
.GUID         18c25998-a474-425e-a59f-e32f79c8431d
.AUTHOR       Kai Kimera
.AUTHOREMAIL  mail@kaikim.ru
.TAGS         windows server backup mail
.LICENSEURI   https://choosealicense.com/licenses/mit/
.PROJECTURI   https://libsys.ru/ru/2024/09/40539e36-4656-5532-b920-8975c97d4dc5/
#>

#Requires -Version 7.2

<#
.SYNOPSIS
Script for sending messages about backup status.

.DESCRIPTION
The script sends messages to the specified address for further analysis.
The messages contain the host ID and notification type.

.EXAMPLE
.\app.backup.wsb.mail.ps1 -Type 'error' [-SSL]

.EXAMPLE
.\app.backup.wsb.mail.ps1 -Type 'success' [-SSL]

.LINK
https://libsys.ru/ru/2024/09/40539e36-4656-5532-b920-8975c97d4dc5/
#>

# -------------------------------------------------------------------------------------------------------------------- #
# CONFIGURATION
# -------------------------------------------------------------------------------------------------------------------- #

param(
  [Alias('H', 'Host')]
  [string]$Hostname = ([System.Net.Dns]::GetHostEntry($env:ComputerName).HostName),

  [ValidateSet('error', 'success')]
  [Alias('T')]
  [string]$Type,

  [Parameter(Mandatory)]
  [Alias('S', 'Subj')]
  [string]$Subject = "Windows Server Backup: ${Hostname}",

  [Parameter(Mandatory)]
  [Alias('F')]
  [string]$From,

  [Parameter(Mandatory)]
  [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{1,}$')]
  [Alias('T')]
  [string[]]$To,

  [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{1,}$')]
  [Alias('C', 'Copy')]
  [string[]]$Cc,

  [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{1,}$')]
  [Alias('BC', 'HideCopy')]
  [string[]]$Bcc,

  [ValidateSet('Low', 'Normal', 'High')]
  [Alias('P')]
  [string]$Priority = 'Normal',

  [switch]$SSL,
  [switch]$BypassCertValid
)

$CFG = ((Get-Item "${PSCommandPath}").Basename + '.ini')
$P = (Get-Content -Path "${PSScriptRoot}\${CFG}" | ConvertFrom-StringData)
$LOG = "${PSScriptRoot}\log.mail.txt"
$UUID = (Get-CimInstance 'Win32_ComputerSystemProduct' | Select-Object -ExpandProperty 'UUID')
$HID = ((${Hostname} + ':' + ${UUID}).ToUpper())
$DATE = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')
$NL = [Environment]::NewLine

# -------------------------------------------------------------------------------------------------------------------- #
# -----------------------------------------------------< SCRIPT >----------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

function Write-BackupError() {
  $Body = @"
Windows Server Backup failed: ${Hostname}.
Please check server backup!

Host: ${Hostname}
Status: ERROR

--
#ID:${HID}
#TYPE:BACKUP:ERROR
"@
}

function Write-BackupSuccess() {
  $Body = @"
Windows Server Backup completed successfully!

Host: ${Hostname}
Status: SUCCESS

--
#ID:${HID}
#TYPE:BACKUP:SUCCESS
"@
}

function Start-Smtp {
  if ($BypassCertValid) { [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true } }
  $SmtpClient = (New-Object Net.Mail.SmtpClient($P.Server, $P.Port))
  $SmtpClient.EnableSsl = $SSL
  $SmtpClient.Credentials = (New-Object System.Net.NetworkCredential($P.User, $P.Password))
  $SmtpClient.Send()
}

function Start-Script() {
  switch ($Type) {
    'error'   { Send-BackupError }
    'success' { Send-BackupSuccess }
    default   { exit }
  }
}; Start-Script
