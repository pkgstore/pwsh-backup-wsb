<#PSScriptInfo
.VERSION      0.1.0
.GUID         18c25998-a474-425e-a59f-e32f79c8431d
.AUTHOR       Kai Kimera
.AUTHOREMAIL  mail@kai.kim
.TAGS         windows server backup mail
.LICENSEURI   https://choosealicense.com/licenses/mit/
.PROJECTURI   https://libsys.ru/ru/2024/09/40539e36-4656-5532-b920-8975c97d4dc5/
#>

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
  [Parameter(HelpMessage='Message type.')]
  [ValidateSet('error', 'success')]
  [string]$Type,
  [Parameter(HelpMessage='Enable or disable encrypted connection.')]
  [switch]$SSL = $false,
  [Alias('Host')][string]$Hostname = ([System.Net.Dns]::GetHostByName([string]'localhost').HostName)
)

$S = ((Get-Item "${PSCommandPath}").Basename + '.ini')
$P = (Get-Content -Path "${PSScriptRoot}\${S}" | ConvertFrom-StringData)
$UUID = (Get-CimInstance 'Win32_ComputerSystemProduct' | Select-Object -ExpandProperty 'UUID')
$HID = ((${Hostname} + ':' + ${UUID}).ToUpper())

# -------------------------------------------------------------------------------------------------------------------- #
# -----------------------------------------------------< SCRIPT >----------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

function Start-Smtp {
  param(
    [Alias('S')][string]$Subject,
    [Alias('B')][string]$Body
  )

  $SmtpClient = New-Object Net.Mail.SmtpClient("$($P.Server)", "$($P.Port)")
  $SmtpClient.EnableSsl = $SSL
  $SmtpClient.Credentials = New-Object System.Net.NetworkCredential("$($P.User)", "$($P.Password)")
  $SmtpClient.Send("$($P.From)", "$($P.To)", "${Subject}", "${Body}")
}

function Send-BackupError() {
  $Subject = "Windows Server Backup: ${Hostname}"
  $Body = @"
Windows Server Backup failed: ${Hostname}.
Please check server backup!

Host: ${Hostname}
Status: ERROR

-- 
#ID:${HID}
#TYPE:BACKUP:ERROR
"@

  Start-Smtp -S "${Subject}" -B "${Body}"
}

function Send-BackupSuccess() {
  $Subject = "Windows Server Backup: ${Hostname}"
  $Body = @"
Windows Server Backup completed successfully!

Host: ${Hostname}
Status: SUCCESS

-- 
#ID:${HID}
#TYPE:BACKUP:SUCCESS
"@

  Start-Smtp -S "${Subject}" -B "${Body}"
}

function Start-Script() {
  switch ("${Type}") {
    'error'   { Send-BackupError }
    'success' { Send-BackupSuccess }
    default   { exit }
  }
}; Start-Script
