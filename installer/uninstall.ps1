param(
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$Target = Join-Path $env:LOCALAPPDATA 'DaFeiYuHOI4'
$Docs = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Paradox Interactive\Hearts of Iron IV'
$ModRoot = Join-Path $Docs 'mod'
$Desktop = [Environment]::GetFolderPath('Desktop')

if ((Split-Path $Target -Leaf) -ne 'DaFeiYuHOI4') {
    throw "拒绝卸载：目标路径异常 $Target"
}

Write-Host ''
Write-Host '=== 大肥鱼 HOI4 卸载 ===' -ForegroundColor Yellow
Write-Host '将删除：配套 mod、桌面快捷方式、软件本体。'
Write-Host '不会动你的存档、游戏本体、其他 mod。'
$answer = if ($Yes) { 'Y' } else { Read-Host '确定卸载？输入 Y 继续' }
if ($answer -notmatch '^[Yy]') { Write-Host '已取消。'; return }

$keep = if ($Yes) { 'Y' } else { Read-Host '卸载前把聊天记忆备份到 Documents？(Y/N)' }
if ($keep -match '^[Yy]') {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmm'
    $backupDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "DaFeiYuHOI4-memory-backup-$stamp"
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    foreach ($name in @('memory.json', 'actions.json')) {
        $src = Join-Path $Target $name
        if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination $backupDir -Force }
    }
    Write-Host "聊天记忆已备份到：$backupDir" -ForegroundColor Green
}

# Stop the companion app if it is still running, so its folder can be removed.
Get-CimInstance Win32_Process |
    Where-Object { $_.CommandLine -and $_.CommandLine -like '*DaFeiYuHOI4.ps1*' -and $_.Name -like 'powershell*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 500

$dlcLoad = Join-Path $Docs 'dlc_load.json'
if (Test-Path -LiteralPath $dlcLoad) {
    Copy-Item -LiteralPath $dlcLoad -Destination "$dlcLoad.bak-dfy-uninstall" -Force
    try {
        $load = Get-Content -LiteralPath $dlcLoad -Raw | ConvertFrom-Json
        $load.enabled_mods = @(@($load.enabled_mods) | Where-Object { $_ -ne 'mod/dafeiyu_hoi4.mod' })
        $load | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $dlcLoad -Encoding UTF8
    } catch {}
}

$modDir = Join-Path $ModRoot 'dafeiyu_hoi4'
$modFile = Join-Path $ModRoot 'dafeiyu_hoi4.mod'
if (Test-Path -LiteralPath $modDir) { Remove-Item -LiteralPath $modDir -Recurse -Force }
if (Test-Path -LiteralPath $modFile) { Remove-Item -LiteralPath $modFile -Force }

foreach ($name in @('大肥鱼 HOI4.lnk', '卸载大肥鱼HOI4.lnk')) {
    $path = Join-Path $Desktop $name
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
}

Write-Host 'mod 和快捷方式已移除。' -ForegroundColor Green
Write-Host '2 秒后删除软件目录...'
Start-Process -FilePath (Join-Path $env:WINDIR 'System32\cmd.exe') `
    -ArgumentList '/c', ('ping 127.0.0.1 -n 3 >nul & rmdir /s /q "' + $Target + '"') `
    -WindowStyle Hidden | Out-Null
