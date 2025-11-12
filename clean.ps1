# clean.ps1
# 关闭系统代理（WinINET + WinHTTP）

$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

New-ItemProperty -Path $regPath -Name "ProxyEnable" -Value 0 -PropertyType DWord -Force | Out-Null
Remove-ItemProperty -Path $regPath -Name "ProxyServer"   -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $regPath -Name "ProxyOverride" -ErrorAction SilentlyContinue

& netsh winhttp reset proxy | Out-Null

Write-Host "已关闭系统代理 (WinINET + WinHTTP 已恢复默认)。" -ForegroundColor Green
