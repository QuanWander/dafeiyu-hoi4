$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$AppSource = Join-Path $Root 'app\DaFeiYuHOI4.ps1'
$ActionsSource = Join-Path $Root 'app\actions.ps1'
$AgentSource = Join-Path $Root 'app\agent.ps1'
$AssetSource = Join-Path $Root 'app\assets'
$ModSource = Join-Path $Root 'mod\dafeiyu_hoi4'
$ModDescriptor = Join-Path $Root 'mod\dafeiyu_hoi4.mod'
$UninstallSource = Join-Path $PSScriptRoot 'uninstall.ps1'
$ReadmeSource = Join-Path $Root 'README.md'
$GuideSource = Join-Path $Root '使用说明.md'
$TutorialSource = Join-Path $Root '安装教程.txt'

$Target = Join-Path $env:LOCALAPPDATA 'DaFeiYuHOI4'
$Docs = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Paradox Interactive\Hearts of Iron IV'
$ModRoot = Join-Path $Docs 'mod'
$Desktop = [Environment]::GetFolderPath('Desktop')
$KeyFile = Join-Path $Target 'key.dat'

if (-not (Test-Path -LiteralPath $AppSource)) { throw "安装包不完整：找不到 $AppSource" }
if (-not (Test-Path -LiteralPath $ActionsSource)) { throw "安装包不完整：找不到 $ActionsSource" }
if (-not (Test-Path -LiteralPath $AgentSource)) { throw "安装包不完整：找不到 $AgentSource" }
if (-not (Test-Path -LiteralPath $ModSource)) { throw "安装包不完整：找不到 $ModSource" }

Write-Host ''
Write-Host '=== 大肥鱼 HOI4 安装 ===' -ForegroundColor Cyan
Write-Host '不会写入注册表，不安装服务，不修改系统目录。'
Write-Host ''

$hoi4Candidates = @(
    'E:\SteamLibrary\steamapps\common\Hearts of Iron IV\hoi4.exe',
    'D:\SteamLibrary\steamapps\common\Hearts of Iron IV\hoi4.exe',
    'C:\Program Files (x86)\Steam\steamapps\common\Hearts of Iron IV\hoi4.exe'
)
$hoi4Found = $hoi4Candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($hoi4Found) {
    Write-Host "检测到 HOI4：$hoi4Found" -ForegroundColor Green
} else {
    Write-Host '没在常见路径检测到 HOI4；软件仍会安装，启动游戏时请手动选 hoi4.exe。' -ForegroundColor Yellow
}

New-Item -ItemType Directory -Force -Path $Target | Out-Null
New-Item -ItemType Directory -Force -Path $ModRoot | Out-Null

Copy-Item -LiteralPath $AppSource -Destination (Join-Path $Target 'DaFeiYuHOI4.ps1') -Force
Copy-Item -LiteralPath $ActionsSource -Destination (Join-Path $Target 'actions.ps1') -Force
Copy-Item -LiteralPath $AgentSource -Destination (Join-Path $Target 'agent.ps1') -Force
if (Test-Path -LiteralPath $AssetSource) {
    $TargetAssets = Join-Path $Target 'assets'
    if (Test-Path -LiteralPath $TargetAssets) { Remove-Item -LiteralPath $TargetAssets -Recurse -Force }
    Copy-Item -LiteralPath $AssetSource -Destination $TargetAssets -Recurse -Force
}
Copy-Item -LiteralPath $UninstallSource -Destination (Join-Path $Target 'uninstall.ps1') -Force
if (Test-Path -LiteralPath $ReadmeSource) { Copy-Item -LiteralPath $ReadmeSource -Destination (Join-Path $Target 'README.md') -Force }
if (Test-Path -LiteralPath $GuideSource) { Copy-Item -LiteralPath $GuideSource -Destination (Join-Path $Target '使用说明.md') -Force }
if (Test-Path -LiteralPath $TutorialSource) { Copy-Item -LiteralPath $TutorialSource -Destination (Join-Path $Target '安装教程.txt') -Force }

$ModTarget = Join-Path $ModRoot 'dafeiyu_hoi4'
if (Test-Path -LiteralPath $ModTarget) { Remove-Item -LiteralPath $ModTarget -Recurse -Force }
Copy-Item -LiteralPath $ModSource -Destination $ModTarget -Recurse -Force
Copy-Item -LiteralPath $ModDescriptor -Destination (Join-Path $ModRoot 'dafeiyu_hoi4.mod') -Force

$DlcLoad = Join-Path $Docs 'dlc_load.json'
if (Test-Path -LiteralPath $DlcLoad) {
    Copy-Item -LiteralPath $DlcLoad -Destination "$DlcLoad.bak-dfy" -Force
    try {
        $load = Get-Content -LiteralPath $DlcLoad -Raw | ConvertFrom-Json
        $mods = @($load.enabled_mods)
        if ($mods -notcontains 'mod/dafeiyu_hoi4.mod') { $mods += 'mod/dafeiyu_hoi4.mod' }
        $load.enabled_mods = @($mods)
        $load | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $DlcLoad -Encoding UTF8
    } catch {
        @{ enabled_mods = @('mod/dafeiyu_hoi4.mod'); disabled_dlcs = @() } |
            ConvertTo-Json | Set-Content -LiteralPath $DlcLoad -Encoding UTF8
    }
} else {
    @{ enabled_mods = @('mod/dafeiyu_hoi4.mod'); disabled_dlcs = @() } |
        ConvertTo-Json | Set-Content -LiteralPath $DlcLoad -Encoding UTF8
}

if (-not (Test-Path -LiteralPath $KeyFile)) {
    Write-Host ''
    Write-Host '首次安装需要 DeepSeek API Key。' -ForegroundColor Yellow
    Write-Host '它只保存在本机，用 Windows DPAPI 加密；不会上传到任何地方。'
    $secure = Read-Host '请粘贴 DeepSeek API Key（输入不会显示）' -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
        if (-not $plain) { throw 'API Key 不能为空。' }
        Add-Type -AssemblyName System.Security
        $bytes = [Text.Encoding]::UTF8.GetBytes($plain)
        $protected = [System.Security.Cryptography.ProtectedData]::Protect(
            $bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        [Convert]::ToBase64String($protected) | Set-Content -LiteralPath $KeyFile -Encoding ASCII
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
} else {
    Write-Host '已有 API Key，保留现有配置。' -ForegroundColor Green
}

$ConfigFile = Join-Path $Target 'config.json'
if (-not (Test-Path -LiteralPath $ConfigFile)) {
    @{ ai = 'ENG'; model = 'deepseek-chat' } | ConvertTo-Json | Set-Content -LiteralPath $ConfigFile -Encoding UTF8
}

$ws = New-Object -ComObject WScript.Shell
$shortcut = $ws.CreateShortcut((Join-Path $Desktop '大肥鱼 HOI4.lnk'))
$shortcut.TargetPath = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
$shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + (Join-Path $Target 'DaFeiYuHOI4.ps1') + '"'
$shortcut.WorkingDirectory = $Target
$shortcut.Description = '大肥鱼 HOI4：和 AI 国家聊天'
$shortcut.IconLocation = 'C:\Windows\System32\shell32.dll,137'
$shortcut.Save()

$uninstallShortcut = $ws.CreateShortcut((Join-Path $Desktop '卸载大肥鱼HOI4.lnk'))
$uninstallShortcut.TargetPath = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
$uninstallShortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $Target 'uninstall.ps1') + '"'
$uninstallShortcut.WorkingDirectory = $Target
$uninstallShortcut.Description = '卸载大肥鱼 HOI4（含配套 mod）'
$uninstallShortcut.IconLocation = 'C:\Windows\System32\shell32.dll,131'
$uninstallShortcut.Save()

Write-Host ''
Write-Host '安装完成。' -ForegroundColor Green
Write-Host '桌面已创建：大肥鱼 HOI4'
Write-Host '桌面已创建：卸载大肥鱼HOI4'
Write-Host ''
Write-Host '第一次进游戏：选国家开局，等一周；然后打开桌面“大肥鱼 HOI4”，选 AI 国家聊天。'
Write-Host '安装教程：' (Join-Path $Target '安装教程.txt')
Write-Host 'mod 安装位置：' $ModTarget

Start-Process -FilePath (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') `
    -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', (Join-Path $Target 'DaFeiYuHOI4.ps1')) | Out-Null
