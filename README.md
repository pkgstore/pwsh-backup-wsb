# Backup: Notifications from Windows Server Backup

## Install

```powershell
$Ver = 'v0.0.0'; $App = 'backup-wsb'; Invoke-Command -ScriptBlock $([scriptblock]::Create((Invoke-WebRequest -Uri 'https://pkgstore.ru/pwsh.install.txt').Content)) -ArgumentList ($args + @($App,$Ver))
```

## Resources

- [Documentation (RU)](https://libsys.ru/ru/2024/09/40539e36-4656-5532-b920-8975c97d4dc5/)
