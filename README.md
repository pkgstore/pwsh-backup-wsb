# Backup: Notifications from Windows Server Backup

## Install

```powershell
$APP = "backup-wsb"; $ORG = "pkgstore"; $PFX = "pwsh-"; $URI = "https://raw.githubusercontent.com/${ORG}/${PFX}${APP}/refs/heads/main"; $META = Invoke-RestMethod -Uri "${URI}/meta.json"; $META.install.file.ForEach({ if (-not (Test-Path "$($_.path)")) { New-Item -Path "$($_.path)" -ItemType "Directory" | Out-Null }; Invoke-WebRequest "${URI}/$($_.name)" -OutFile "$($_.path)" })
```

## Resources

- [Documentation (RU)](https://libsys.ru/ru/2024/09/40539e36-4656-5532-b920-8975c97d4dc5/)
