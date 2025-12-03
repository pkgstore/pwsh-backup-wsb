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
  [string]$Hostname = ([System.Net.Dns]::GetHostEntry([System.Environment]::MachineName).HostName),
  [string]$Subject = "Windows Server Backup: ${Hostname}",
  [Parameter(Mandatory)][string]$From,
  [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{1,}$')][string[]]$To,
  [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{1,}$')][string[]]$Cc,
  [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{1,}$')][string[]]$Bcc,
  [ValidateSet('Low', 'Normal', 'High')][string]$Priority = 'Normal',
  [ValidateSet('error')][string]$Type,
  [switch]$HTML,
  [switch]$SSL,
  [switch]$BypassCertValid
)

$CFG = ((Get-Item "${PSCommandPath}").Basename + '.ini')
$P = (Get-Content -Path "${PSScriptRoot}\${CFG}" | ConvertFrom-StringData)
$LOG = "${PSScriptRoot}\log.backup.wsb.mail.txt"
$UUID = (Get-CimInstance 'Win32_ComputerSystemProduct' | Select-Object -ExpandProperty 'UUID')
$HID = (-join ($Hostname, ':', $UUID).ToUpper())
$IP = ([System.Net.DNS]::GetHostAddresses([System.Environment]::MachineName)
  | Where-Object { $_.AddressFamily -eq 'InterNetwork' })[0].ToString()
$DATE = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')
$NL = [Environment]::NewLine

# -------------------------------------------------------------------------------------------------------------------- #
# -----------------------------------------------------< SCRIPT >----------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

function Write-Sign {
  $Sign = switch ( $true ) {
    $HTML {
      -join (
        '<br><br>-- <ul>',
        "<li><pre><code>#ID:${HID}</code></pre></li>",
        "<li><pre><code>#IP:${IP}</code></pre></li>",
        "<li><pre><code>#DATE:${DATE}</code></pre></li>",
        '</ul>'
      )
    }
    default {
      -join (
        "${NL}${NL}-- ",
        "${NL}#ID:${HID}",
        "${NL}#IP:${IP}",
        "${NL}#DATE:${DATE}"
      )
    }
  }

  return $Sign
}

function Write-Body() {
  $Body = switch ($Type) {
    'error' {
      if ($HTML) {
        -join (
          '<p>Windows Server Backup failed! Please check server backup!</p>',
          '<ul>',
          "<li>Host: <code>${Hostname}</code></li>",
          "<li>IP: <code>${IP}</code></li>",
          '</ul>'
        )
      } else {
        -join (
          'Windows Server Backup failed! Please check server backup!',
          "${NL}Host: ${Hostname}",
          "${NL}IP: ${IP}"
        )
      }
    }
    default {
      'Windows Server Backup completed successfully!'
    }
  }

  return $Body
}

function Write-Mail {
  $Mail = (New-Object System.Net.Mail.MailMessage)
  $Mail.Subject = $Subject
  $Mail.Body = (-join ($(Write-Body), $(Write-Sign)))
  $Mail.From = $From
  $Mail.Priority = $Priority
  $Mail.IsBodyHtml = $HTML

  $To.ForEach({ $Mail.To.Add($_) })
  $Cc.ForEach({ $Mail.CC.Add($_) })
  $Bcc.ForEach({ $Mail.BCC.Add($_) })

  return $Mail
}

function Start-Smtp {
  if ($BypassCertValid) { [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true } }
  $SmtpClient = (New-Object Net.Mail.SmtpClient($P.Server, $P.Port))
  $SmtpClient.EnableSsl = $SSL
  $SmtpClient.Credentials = (New-Object System.Net.NetworkCredential($P.User, $P.Password))
  $SmtpClient.Send($(Write-Mail))
}

function Start-Script() {
  Start-Transcript -Path "${LOG}"
  Start-Smtp
  Stop-Transcript
}; Start-Script
