# ============================================
# heytea-diy.ps1
# 启动打包后的 heytea-diy.exe + 自动证书 + 自动系统代理
# 必须以管理员身份运行
# ============================================

param(
    [int]$P = 8080   # 不传参数时默认 8080
)

function Test-MitMCertInstalled {
    param(
        [string]$CertPath
    )

    if (-not (Test-Path $CertPath)) {
        return $false
    }

    # 从文件加载证书，拿到指纹
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertPath)
    $thumb = $cert.Thumbprint

    # 在 本地计算机 的 Root 存储里查找同指纹证书
    $exists = Get-ChildItem -Path Cert:\LocalMachine\Root |
        Where-Object { $_.Thumbprint -eq $thumb }

    return ($exists -ne $null)
}

# 1. 检查是否管理员权限
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "请【以管理员身份】运行此脚本：右键 PowerShell -> 以管理员身份运行。" -ForegroundColor Red
    exit 1
}

# 2. 参数配置（可根据实际情况修改）
$proxyHost = "127.0.0.1"
$proxyPort = $P          # 监听端口

# mitmproxy 证书目录（Windows 默认：C:\Users\xxx\.mitmproxy）
$mitmDir = Join-Path $env:USERPROFILE ".mitmproxy"
$caFileCer  = Join-Path $mitmDir "mitmproxy-ca-cert.cer"  # 用于 certutil 导入

# heytea-diy.exe 路径（假设与脚本在同一目录）
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$proxyExe  = Join-Path $scriptDir "heytea-diy.exe"

Write-Host "脚本所在目录：$scriptDir"
Write-Host "代理程序路径：$proxyExe"
Write-Host ""

if (-not (Test-Path $proxyExe)) {
    Write-Host "错误：未找到 $proxyExe，请确认脚本与 heytea-diy.exe 在同一目录。" -ForegroundColor Red
    exit 1
}

# 3. 启动 heytea-diy.exe（如果还没启动的话）
$existing = Get-Process -Name "heytea-diy" -ErrorAction SilentlyContinue
if ($null -eq $existing) {
    Write-Host "未检测到运行中的 heytea-diy.exe，正在启动..." -ForegroundColor Cyan
    # 不用 -Wait，让它在后台持续跑
    $startArgs = @("-p", $proxyPort)
    Start-Process -FilePath $proxyExe -ArgumentList $startArgs
} else {
    Write-Host "检测到 heytea-diy.exe 已在运行，跳过启动步骤。" -ForegroundColor Yellow
}

# 4. 等待 mitmproxy 生成 CA 证书 (~\.mitmproxy\mitmproxy-ca-cert.cer)
Write-Host ""
Write-Host "等待 mitmproxy 生成 CA 证书文件..." -ForegroundColor Cyan

$maxWaitSeconds = 60
$elapsed = 0
while (-not (Test-Path $caFileCer) -and $elapsed -lt $maxWaitSeconds) {
    Start-Sleep -Seconds 1
    $elapsed++
}

if (-not (Test-Path $caFileCer)) {
    Write-Host "在 $maxWaitSeconds 秒内没有检测到证书文件：$caFileCer" -ForegroundColor Red
    Write-Host "请确认 heytea-diy.exe 能正常运行，或者手动访问 http://mitm.it 生成证书后再重试。"
    exit 1
}

Write-Host "已找到 mitmproxy CA 证书：$caFileCer" -ForegroundColor Green

# 5. 导入证书到“受信任的根证书颁发机构 (Root)”
Write-Host ""

if (Test-MitMCertInstalled -CertPath $caFileCer) {
    Write-Host "检测到 mitmproxy 证书已存在于【本地计算机\\受信任的根证书颁发机构 (Root)】存储，跳过导入。" -ForegroundColor Yellow
} else {
    Write-Host "未在 Root 存储中发现该 mitmproxy 证书，正在导入..." -ForegroundColor Cyan

    $certutilCmd = "certutil.exe"
    $certArgs    = "-addstore", "-f", "Root", "`"$caFileCer`""

    $proc = Start-Process -FilePath $certutilCmd -ArgumentList $certArgs -Wait -PassThru -WindowStyle Hidden

    if ($proc.ExitCode -ne 0) {
        Write-Host "证书导入失败，certutil 退出码：$($proc.ExitCode)" -ForegroundColor Red
        exit 1
    }

    Write-Host "证书导入成功。" -ForegroundColor Green
}

# 6. 配置当前用户 WinINET 系统代理（Windows 设置里看到的那个代理）
Write-Host ""
Write-Host "正在配置当前用户的系统代理 (WinINET) ..." -ForegroundColor Cyan

$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

# 开启代理
New-ItemProperty -Path $regPath -Name "ProxyEnable"  -Value 1 -PropertyType DWord  -Force | Out-Null

# 设置代理地址
$proxyString = "$proxyHost`:$proxyPort"
New-ItemProperty -Path $regPath -Name "ProxyServer"  -Value $proxyString -PropertyType String -Force | Out-Null

# 代理例外：本地地址不走代理
New-ItemProperty -Path $regPath -Name "ProxyOverride" -Value "<local>" -PropertyType String -Force | Out-Null

Write-Host "WinINET 系统代理已设置为：$proxyString" -ForegroundColor Green

# 7. 配置 WinHTTP 代理（部分系统服务/CLI 使用）
Write-Host ""
Write-Host "正在配置 WinHTTP 代理 ..." -ForegroundColor Cyan

$winhttpProxy = "$proxyHost`:$proxyPort"
& netsh winhttp set proxy $winhttpProxy | Out-Null

Write-Host "WinHTTP 代理已设置为：$winhttpProxy" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "mitmproxy 已启动，证书导入完成，系统代理已开启。" -ForegroundColor Green
Write-Host "当前代理：$proxyHost`:$proxyPort" -ForegroundColor Green
Write-Host "如果要验证，可以打开浏览器访问 http://mitm.it" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
