$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$AppData = Join-Path $env:LOCALAPPDATA 'DaFeiYuHOI4'
$KeyFile = Join-Path $AppData 'key.dat'
$ConfigFile = Join-Path $AppData 'config.json'
$MemoryFile = Join-Path $AppData 'memory.json'
$ActionsFile = Join-Path $AppData 'actions.json'
$AdvisorFile = Join-Path $AppData 'advisor.json'
$script:appVersion = '0.9.19'
$DocsRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Paradox Interactive\Hearts of Iron IV'
$LogPath = Join-Path $DocsRoot 'logs\game.log'
New-Item -ItemType Directory -Force -Path $AppData | Out-Null

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$UiBg = [Drawing.Color]::FromArgb(18, 18, 17)
$UiSide = [Drawing.Color]::FromArgb(26, 24, 21)
$UiCard = [Drawing.Color]::FromArgb(36, 33, 28)
$UiCard2 = [Drawing.Color]::FromArgb(48, 43, 36)
$UiText = [Drawing.Color]::FromArgb(231, 224, 211)
$UiMuted = [Drawing.Color]::FromArgb(158, 148, 134)
$UiCyan = [Drawing.Color]::FromArgb(145, 168, 175)
$UiBlue = [Drawing.Color]::FromArgb(122, 45, 38)
$UiGreen = [Drawing.Color]::FromArgb(120, 139, 112)
$UiRed = [Drawing.Color]::FromArgb(190, 88, 72)
$UiBubbleAi = [Drawing.Color]::FromArgb(42, 38, 32)
$UiBubbleUser = [Drawing.Color]::FromArgb(82, 34, 30)

. (Join-Path $PSScriptRoot 'actions.ps1')

$script:helpSections = [ordered]@{
    '第一次使用' = @"
## 第一次使用

1. 打开 HOI4，选你想玩的国家，正常开局。
2. 在游戏里过一周，让配套 mod 写下第一批状态。
3. 打开桌面“大肥鱼 HOI4”，左侧会自动识别你玩的国家。
4. 想让 AI 扮演别的国家：在“AI 国家”里选一个非玩家国家，然后说话。
5. 想让大肥鱼当你的参谋：点右上角“同国参谋”，再点“资料”补充国策/生产/编制。

如果软件把你玩的国家认错了：
点“你：ITA”旁边的 **改**，手动选你实际玩的国家；
也可以点“自动识别”重新读当前存档。

如果 AI 国家列表是空的：
· 确认启动器播放集里勾选了 DaFeiYu HOI4；
· 进游戏后过一周；
· 或读一次档再等一周。
"@
    '游戏内指令' = @"
## 游戏内指令：~ / Ctrl+V / 回车

这不是三条命令，是三个键盘动作：

1. 按 ~ 打开 HOI4 控制台
2. 按 Ctrl+V 粘贴软件已经复制好的命令
3. 按回车执行

~ 在 Esc 下面、数字 1 左边。英文输入状态下按；
如果没反应，按 Shift + 这个键，或换英文键盘布局。

控制台打不开：
· 游戏必须用 -debug_mode 启动；
· 软件里的“启动游戏”已经带了这个参数；
· 从 Steam 直接启动可能没有控制台。

示例命令：
eval_effect ENG = { add_to_faction = GER }

粘贴后按回车，再按一次 ~ 关闭控制台。

聊天框输入 /下令 也可以直接打开“给 AI 下令”面板；
普通聊天不受影响。
"@
    '行动与验证' = @"
## 行动与验证

软件不会假装替你按键盘：HOI4 会屏蔽模拟按键。
所以行动窗口只负责：
· 生成命令；
· 自动复制；
· 给你三步指引。

现在指令库分 10 类、50 条：
· 下单窗口先选类别，默认“常用”只放 10 条；
· 外交：结盟、保障、宣战、白和；
· 阵营：退出、踢人、解散、改名、当领袖；
· 经济：民用工厂、军工、船坞、基础设施；
· 科研：科研槽；
· 政治：政治点、稳定度、战争支持度；
· 军事：指挥点、人力、装备、燃料、陆/海/空经验；
· 强制/不平等：拉目标进阵营、逼目标退阵营、强制通行、附庸、吞并；
· 对玩家：给通行、邀请/逼退阵营、送装备/燃料/政治点/指挥点/人力、打压稳定/战争支持；
· 国家：转州、州宣称、设核心、完成焦点、加国家精神（需要手动填 ID）；\n· 玩家装备：具体装备需要先研究；没研究就用“送玩家最新装备”。

你可以不等 AI 同意，直接在“行动”里主动选；
高风险命令会标红，极高风险会二次确认。
最下面还有“自定义指令”，可以写任意 effect，
用 {AI} 和 {PLAYER} 代替国家，后果自负。

下一周状态更新后，软件会验证：
· 投资民用/军工/船坞：工厂数是否增加；
· 科研槽：槽位是否增加；
· 政治点/稳定度/战争支持度：数值是否增加；
· 宣战/白和：战争状态是否改变；
· 结盟/保障：关系日志里是否出现玩家。

验证状态：
· applied：已经生效；
· pending：等待下一周；
· unverified：超时没看到变化，可能条件不满足。

同一个行动 45 秒内重复，会先问你一次。
"@
    '同国参谋（A）' = @"
## 同国参谋（A）

主界面右上角的 **同国参谋** 开关，不是让 AI 扮演敌国，
而是让大肥鱼看**你玩的这个国家**，当参谋。

开启后：
· 状态卡切到玩家国；
· AI 国家下拉禁用；
· 行动按钮禁用；
· 快捷问法变成“下一步国策 / 内政优先级 / 战争风险”；
· 回复身份显示“大肥鱼 · 参谋”。

### 参谋资料

点右上角 **资料**，可以填：
· 国策/分支；
· 科研；
· 建造；
· 生产；
· 编制/部队；
· 法律/顾问/政治；
· 目标/约束。

国策会读取当前玩家国的焦点树，可搜索下拉，也可以手写；
所有字段都可以留空，只写一句也行。
资料按“本局 + 玩家国”保存，不会混进敌国对话。

### 她能看到什么

每周国力快照：
民用/军工/船坞、师、人力、舰船、飞机、
政治点、稳定、战争支持、科研槽、阵营、敌国。

### 她看不到什么

· 国策树具体进度；
· 科研队列；
· 建造队列；
· 生产队列；
· 师编制；
· 部队位置；
· 法律/顾问槽。

所以她会问你要这些资料，不会假装全知。

### 边界

A 是参谋：给建议、优先级、代价和风险。
A 不是代管：不点游戏、不排生产线、不移动部队、不自动执行。

### A 下一步可做

1. 国策下拉按 x/y + prerequisite 分组，做成真正的分支；
2. 一键生成“参谋简报”：国策/建造/科研/生产/编制五段式；
3. 结构化内政计划：给优先级，但不自动执行；
4. 增加“本局决策记录”，对比建议和实际结果；
5. 如果能稳定读取存档/文本遥测，再减少手填。

B 同国代管不在 A 里承诺：需要硬件 HID + 屏幕识别或 DLL，
风险高、非创意工坊路线。
"@
    '记忆与承诺' = @"
## 记忆与承诺

聊到 15 轮以上，软件会把旧消息整理成：
· 本局摘要；
· 承诺账本（谁答应过什么）。

左侧“记忆”可以查看：
· 摘要；
· 仍有效的承诺；
· 最近行动和验证状态；
· 清空当前对话。

摘要和承诺会重新喂给 AI，所以聊久了不会把前面的话全忘掉。
摘要整理会多一次 API 调用，已经尽量降低频率。
"@
    '国家标识与隐私' = @"
## 国家标识与隐私

国家标识统一使用：
字母 + 色块（例如 ENG / ITA / SOV）。

不显示任何真实国旗，
也不再附带 HOI4 游戏旗帜素材。

API Key：
· 只存本机；
· Windows DPAPI 加密；
· 不上传；
· 聊天只发到 DeepSeek API。
"@
    'Key 与费用' = @"
## Key 与费用

首次安装会要求 DeepSeek API Key。
设置里可以：
· 换模型；
· 换 Key；
· 测试 Key（会消耗少量 tokens）。

费用按 token 计，普通一局通常几毛到几块。
软件不会后台自动刷 API，只有你发送时才调用。
"@
    '安装 / 更新 / 卸载' = @"
## 安装 / 更新 / 卸载

安装：
· 解压 ZIP；
· 双击“安装.cmd”；
· 首次粘贴 Key。

更新：
· 直接运行新 ZIP 的“安装.cmd”覆盖安装；
· 聊天记忆在 LocalAppData，不会被覆盖。

卸载：
· 双击桌面“卸载大肥鱼HOI4”；
· 会问是否把聊天记忆备份到 Documents；
· 不动存档、游戏本体、其他 mod。
"@
    '常见问题' = @"
## 常见问题

Q：AI 国家列表是空的？
A：如果游戏在跑但列表空，看诊断里的 mods；mods=0 表示这次启动没加载 mod。
   保存退出，确认播放集勾选 DaFeiYu HOI4，重新启动，再过一周。
   mod 不能热加载，运行中改播放集没用。

Q：控制台打不开？
A：用软件里的“启动游戏”，它带 -debug_mode。

Q：命令粘贴了没反应？
A：看下一周国力卡/关系是否变化；可能条件不满足。

Q：请求失败 401 / 422？
A：401 是 Key 或余额；422 是消息格式，升级到最新版。

Q：能中途换玩家国吗？
A：游戏本身不支持；换国请新开档。

Q：同国参谋为什么不知道我的国策/生产？
A：当前只有每周国力快照，没有国策树进度、生产/建造队列、编制和部队位置。
   点右上角“资料”补充，或让她先问你；不要把“不知道”当成她坏了。

Q：同国参谋能不能替我操作？
A：不能。A 只给建议；行动按钮会禁用。B 代管需要外部自动化，风险高，未承诺。
"@
    '本版更新' = @"
## 本版更新：v$($script:appVersion)

· 新增 **同国参谋（A）**：右上角开关，切到玩家国视角；
· 新增参谋资料面板：国策/科研/建造/生产/编制/法律/目标；
· 国策字段读取本国焦点树，可搜索下拉、手写、留空；
· 参谋模式不输出 [ACTION]、不生成命令、行动按钮禁用；
· 修复左上角标题/副标题被 300px 侧栏裁切；
· 新增软件内帮助中心，首次启动自动弹出一次；
· 主界面常驻“帮助”按钮；
· 游戏内指令、行动验证、记忆、隐私、卸载都有说明；
· 帮助内容跟随版本更新，本页就是当前版；
· 行动扩到 50 条：外交/阵营/经济/科研/政治/军事/强制/对玩家/国家；
· 下单窗口改成“先选类别，再选指令”，默认常用 10 条；
· 玩家可主动下令，不必等 AI 同意；高风险标红；
· 新增强制附庸/吞并/拉阵营/退阵营/通行，极高风险二次确认；
· 新增对玩家：通行、邀请/逼退阵营、送装备/燃料/政治点/指挥点/人力、打压稳定/战争支持；
· 新增国家：转州、州宣称、设核心、完成焦点、加国家精神；需要手填 ID；
· 新增自定义 effect 指令，{AI}/{PLAYER} 占位；
· 修复玩家国识别：优先读 continue_game，跳过二进制存档误匹配；
· 玩家国旁边新增“改”，识别错了可手动指定；
· 游戏在跑但 mod 没加载时，直接提示 Active Mod Count 0。

遇到没写到的情况：
点“复制诊断信息”，把版本、路径、状态一起发出来。
"@
}

function Read-Config {
    $cfg = @{ ai = 'ENG'; model = 'deepseek-chat'; help_seen = ''; player_override = '' }
    if (Test-Path -LiteralPath $ConfigFile) {
        try {
            $saved = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
            if ($saved.ai) { $cfg.ai = [string]$saved.ai }
            if ($saved.model) { $cfg.model = [string]$saved.model }
            if ($saved.help_seen) { $cfg.help_seen = [string]$saved.help_seen }
            if ($saved.player_override) { $cfg.player_override = [string]$saved.player_override }
        } catch {}
    }
    return $cfg
}

function Save-Config($cfg) {
    $cfg | ConvertTo-Json | Set-Content -LiteralPath $ConfigFile -Encoding UTF8
}

function Read-Key {
    if (-not (Test-Path -LiteralPath $KeyFile)) { return $null }
    try {
        Add-Type -AssemblyName System.Security
        $encoded = (Get-Content -LiteralPath $KeyFile -Raw).Trim()
        $bytes = [Convert]::FromBase64String($encoded)
        $plain = [System.Security.Cryptography.ProtectedData]::Unprotect(
            $bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        return [Text.Encoding]::UTF8.GetString($plain)
    } catch { return $null }
}

function Save-Key([string]$key) {
    Add-Type -AssemblyName System.Security
    $bytes = [Text.Encoding]::UTF8.GetBytes($key)
    $protected = [System.Security.Cryptography.ProtectedData]::Protect(
        $bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    [Convert]::ToBase64String($protected) | Set-Content -LiteralPath $KeyFile -Encoding ASCII
}

function Find-Hoi4 {
    $candidates = New-Object System.Collections.Generic.List[string]
    $steam = $null
    try { $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction SilentlyContinue).SteamPath } catch {}
    $roots = @()
    if ($steam) { $roots += $steam }
    foreach ($drive in @('C', 'D', 'E', 'F', 'G')) {
        $roots += "${drive}:\Steam"
        $roots += "${drive}:\Program Files (x86)\Steam"
    }
    foreach ($root in ($roots | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        $candidates.Add((Join-Path $root 'steamapps\common\Hearts of Iron IV\hoi4.exe'))
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            try {
                $content = Get-Content -LiteralPath $vdf -Raw
                foreach ($match in [regex]::Matches($content, '"path"\s+"([^"]+)"')) {
                    $lib = $match.Groups[1].Value -replace '\\\\', '\'
                    $candidates.Add((Join-Path $lib 'steamapps\common\Hearts of Iron IV\hoi4.exe'))
                }
            } catch {}
        }
    }
    foreach ($path in $candidates) {
        if (Test-Path -LiteralPath $path) { return $path }
    }
    return $null
}

function Get-ModLoadCount {
    $systemLog = Join-Path $DocsRoot 'logs\system.log'
    if (Test-Path -LiteralPath $systemLog) {
        try {
            $text = Get-Content -LiteralPath $systemLog -Raw
            $matches = [regex]::Matches($text, 'Active Mod Count:\s*(\d+)')
            if ($matches.Count -gt 0) { return [int]$matches[$matches.Count - 1].Groups[1].Value }
        } catch {}
    }
    return $null
}

function Detect-Player {
    $continuePath = Join-Path $DocsRoot 'continue_game.json'
    if (Test-Path -LiteralPath $continuePath) {
        try {
            $title = (Get-Content -LiteralPath $continuePath -Raw | ConvertFrom-Json).title
            $map = [ordered]@{
                '意大利' = 'ITA'; '德意志' = 'GER'; '德国' = 'GER'; '联合王国' = 'ENG'; '英国' = 'ENG';
                '法兰西' = 'FRA'; '法国' = 'FRA'; '苏维埃' = 'SOV'; '苏联' = 'SOV';
                '美利坚' = 'USA'; '美国' = 'USA'; '日本' = 'JAP';
                '中华民国' = 'CHI'; '中国' = 'CHI'; '波兰' = 'POL'; '加拿大' = 'CAN';
                '澳大利亚' = 'AST'; '印度' = 'RAJ'
            }
            foreach ($name in $map.Keys) {
                if ($title -like "*$name*") { return $map[$name] }
            }
        } catch {}
    }

    $saveDir = Join-Path $DocsRoot 'save games'
    if (Test-Path -LiteralPath $saveDir) {
        $saves = Get-ChildItem -LiteralPath $saveDir -Filter '*.hoi4' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending
        foreach ($save in $saves) {
            try {
                $fs = [IO.File]::Open($save.FullName, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
                $buffer = New-Object byte[] 131072
                $read = $fs.Read($buffer, 0, $buffer.Length)
                $fs.Close()
                $text = [Text.Encoding]::UTF8.GetString($buffer, 0, $read)
                if ($text -match '^\s*HOI4bin') { continue }
                $match = [regex]::Match($text, 'player\s*=\s*"([A-Z0-9]{3})"')
                if ($match.Success) { return $match.Groups[1].Value.ToUpperInvariant() }
            } catch {}
        }
    }
    return $null
}

function Get-CampaignInfo {
    $continuePath = Join-Path $DocsRoot 'continue_game.json'
    if (Test-Path -LiteralPath $continuePath) {
        try {
            $cg = Get-Content -LiteralPath $continuePath -Raw | ConvertFrom-Json
            $title = [string]$cg.title
            $stable = ($title -replace '\s+\d{4}\.\d+\.\d+\.\d+.*$', '').Trim()
            if (-not $stable) { $stable = $title }
            $key = "$($script:player)|$stable"
            if ($key) { return @{ Key = $key; Title = $title } }
        } catch {}
    }
    return @{ Key = "$($script:player)|unknown-campaign"; Title = '未识别本局' }
}

function Load-Memory {
    if (Test-Path -LiteralPath $MemoryFile) {
        try {
            $data = Get-Content -LiteralPath $MemoryFile -Raw | ConvertFrom-Json
            if ($data) { return $data }
        } catch {}
    }
    return (New-Object psobject)
}

function Save-Memory($memory) {
    try { $memory | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $MemoryFile -Encoding UTF8 } catch {}
}

function Normalize-History($history) {
    $flat = New-Object System.Collections.ArrayList
    foreach ($item in @($history)) {
        if ($null -eq $item) { continue }
        if ($item -is [string]) { continue }
        if ($item -is [System.Array]) {
            foreach ($sub in $item) {
                if ($sub -and $sub.role -and $sub.content) {
                    [void]$flat.Add(@{ role = [string]$sub.role; content = [string]$sub.content; time = [string]$sub.time })
                }
            }
            continue
        }
        if ($item.role -and $item.content) {
            [void]$flat.Add(@{ role = [string]$item.role; content = [string]$item.content; time = [string]$item.time })
            continue
        }
        if ($item -is [System.Collections.IEnumerable]) {
            foreach ($sub in $item) {
                if ($sub -and $sub.role -and $sub.content) {
                    [void]$flat.Add(@{ role = [string]$sub.role; content = [string]$sub.content; time = [string]$sub.time })
                }
            }
        }
    }
    return @($flat)
}

function Get-Memory([string]$tag) {
    if (-not $tag) { return @() }
    $key = "$script:campaignKey|$tag"
    $result = @()
    if ($script:memory.PSObject.Properties.Name -contains $key) {
        $result = @(Normalize-History $script:memory.$key)
    } elseif ($script:memory.PSObject.Properties.Name -contains $tag) {
        $result = @(Normalize-History $script:memory.$tag)
        $script:memory | Add-Member -NotePropertyName $key -NotePropertyValue $result -Force
        Save-Memory $script:memory
    }
    return @($result)
}

function Set-Memory([string]$tag, $history) {
    $key = "$script:campaignKey|$tag"
    $clean = @(Normalize-History $history)
    $script:memory | Add-Member -NotePropertyName $key -NotePropertyValue @($clean) -Force
    Save-Memory $script:memory
}

function Get-Summary([string]$tag) {
    $key = "$script:campaignKey|$tag|summary"
    if ($script:memory.PSObject.Properties.Name -contains $key) { return [string]$script:memory.$key }
    return ''
}

function Set-Summary([string]$tag, [string]$summary) {
    $key = "$script:campaignKey|$tag|summary"
    $script:memory | Add-Member -NotePropertyName $key -NotePropertyValue $summary -Force
    Save-Memory $script:memory
}

function Get-Ledger([string]$tag) {
    $key = "$script:campaignKey|$tag|ledger"
    if ($script:memory.PSObject.Properties.Name -contains $key) { return @($script:memory.$key) }
    return @()
}

function Set-Ledger([string]$tag, $ledger) {
    $key = "$script:campaignKey|$tag|ledger"
    $script:memory | Add-Member -NotePropertyName $key -NotePropertyValue @($ledger) -Force
    Save-Memory $script:memory
}

function Get-AdvisorKey {
    return "$script:campaignKey|$script:player"
}

function Get-AdvisorStore {
    if ($script:advisorStore) { return $script:advisorStore }
    $store = @{}
    if (Test-Path -LiteralPath $AdvisorFile) {
        try {
            $data = Get-Content -LiteralPath $AdvisorFile -Raw | ConvertFrom-Json
            if ($data) {
                foreach ($prop in $data.PSObject.Properties) { $store[$prop.Name] = $prop.Value }
            }
        } catch {}
    }
    $script:advisorStore = $store
    return $store
}

function Get-AdvisorContext {
    $store = Get-AdvisorStore
    $key = Get-AdvisorKey
    if ($store.ContainsKey($key)) { return $store[$key] }
    return [pscustomobject]@{}
}

function Save-AdvisorContext($ctx) {
    $store = Get-AdvisorStore
    $store[(Get-AdvisorKey)] = $ctx
    $script:advisorStore = $store
    try { $store | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $AdvisorFile -Encoding UTF8 } catch {}
}

function Get-AdvisorContextText {
    $ctx = Get-AdvisorContext
    $fields = @(
        @{ key = 'focus'; label = '国策' },
        @{ key = 'research'; label = '科研' },
        @{ key = 'construction'; label = '建造' },
        @{ key = 'production'; label = '生产' },
        @{ key = 'army'; label = '编制/部队' },
        @{ key = 'politics'; label = '法律/顾问/政治' },
        @{ key = 'goal'; label = '目标/约束' }
    )
    $lines = @()
    foreach ($f in $fields) {
        $v = [string]$ctx.($f.key)
        if ($v.Trim()) { $lines += "- $($f.label)：$($v.Trim())" }
    }
    if ($lines.Count -eq 0) { return '暂无；信息不足时先问玩家。' }
    return ($lines -join "`n")
}

function Load-Actions {
    if (Test-Path -LiteralPath $ActionsFile) {
        try {
            $data = Get-Content -LiteralPath $ActionsFile -Raw | ConvertFrom-Json
            if ($data) { return $data }
        } catch {}
    }
    return (New-Object psobject)
}

function Save-Actions($actions) {
    try { $actions | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ActionsFile -Encoding UTF8 } catch {}
}

function Get-ActionHistory([string]$tag) {
    $data = Load-Actions
    $key = "$script:campaignKey|$tag"
    if ($data.PSObject.Properties.Name -contains $key) { return @($data.$key) }
    return @()
}

function Add-ActionHistory([string]$tag, [string]$action, [string]$command, $state) {
    $data = Load-Actions
    $key = "$script:campaignKey|$tag"
    $list = @()
    if ($data.PSObject.Properties.Name -contains $key) { $list = @($data.$key) }
    $rel = Get-Relations $tag
    $entry = @{
        time = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        action = $action
        command = $command
        status = 'pending'
        before_civ = if ($state) { [string]$state.civ } else { '' }
        before_mil = if ($state) { [string]$state.mil } else { '' }
        before_dock = if ($state) { [string]$state.dock } else { '' }
        before_res = if ($state) { [string]$state.res } else { '' }
        before_pp = if ($state) { [string]$state.pp } else { '' }
        before_stab = if ($state) { [string]$state.stab } else { '' }
        before_ws = if ($state) { [string]$state.ws } else { '' }
        before_war = if ($state) { [string]$state.war } else { '' }
        before_join = if ($rel.inFactionWithPlayer) { '1' } else { '0' }
        before_guarantee = if ($rel.guaranteesPlayer) { '1' } else { '0' }
    }
    $list += $entry
    $data | Add-Member -NotePropertyName $key -NotePropertyValue @($list) -Force
    Save-Actions $data
}

function Update-ActionHistory([string]$tag, $state) {
    if (-not $state) { return }
    $data = Load-Actions
    $key = "$script:campaignKey|$tag"
    if (-not ($data.PSObject.Properties.Name -contains $key)) { return }
    $list = @($data.$key)
    $rel = Get-Relations $tag
    $changed = $false
    for ($i = 0; $i -lt $list.Count; $i++) {
        $item = $list[$i]
        if ([string]$item.status -ne 'pending') { continue }
        $applied = $false
        if ($item.action -eq 'invest_civ' -and $item.before_civ -match '^\d+$' -and $state.civ -match '^\d+$') {
            if ([int]$state.civ -gt [int]$item.before_civ) { $applied = $true }
        }
        if ($item.action -eq 'invest_mil' -and $item.before_mil -match '^\d+$' -and $state.mil -match '^\d+$') {
            if ([int]$state.mil -gt [int]$item.before_mil) { $applied = $true }
        }
        if ($item.action -eq 'invest_dock' -and $item.before_dock -match '^\d+$' -and $state.dock -match '^\d+$') {
            if ([int]$state.dock -gt [int]$item.before_dock) { $applied = $true }
        }
        if ($item.action -eq 'research' -and $item.before_res -match '^\d+$' -and $state.res -match '^\d+$') {
            if ([int]$state.res -gt [int]$item.before_res) { $applied = $true }
        }
        if ($item.action -eq 'boost_pp' -and $item.before_pp -match '^-?\d+(\.\d+)?$' -and $state.pp -match '^-?\d+(\.\d+)?$') {
            if ([double]$state.pp -gt [double]$item.before_pp) { $applied = $true }
        }
        if ($item.action -eq 'boost_stability' -and $item.before_stab -match '^-?\d+(\.\d+)?$' -and $state.stab -match '^-?\d+(\.\d+)?$') {
            if ([double]$state.stab -gt [double]$item.before_stab) { $applied = $true }
        }
        if ($item.action -eq 'boost_war_support' -and $item.before_ws -match '^-?\d+(\.\d+)?$' -and $state.ws -match '^-?\d+(\.\d+)?$') {
            if ([double]$state.ws -gt [double]$item.before_ws) { $applied = $true }
        }
        if ($item.action -eq 'declare_war' -and [string]$state.war -eq '1' -and [string]$item.before_war -eq '0') {
            $applied = $true
        }
        if ($item.action -eq 'white_peace' -and [string]$state.war -eq '0' -and [string]$item.before_war -eq '1') {
            $applied = $true
        }
        if ($item.action -eq 'join_faction' -and $rel.inFactionWithPlayer -and [string]$item.before_join -ne '1') {
            $applied = $true
        }
        if ($item.action -eq 'guarantee' -and $rel.guaranteesPlayer -and [string]$item.before_guarantee -ne '1') {
            $applied = $true
        }
        if ($applied) {
            $item.status = 'applied'
            $changed = $true
        } elseif (((Get-Date) - [datetime]$item.time).TotalSeconds -gt 90) {
            $item.status = 'unverified'
            $changed = $true
        }
    }
    if ($changed) {
        $data | Add-Member -NotePropertyName $key -NotePropertyValue @($list) -Force
        Save-Actions $data
    }
}

function Invoke-ChatApi($messages, [int]$maxTokens = 700) {
    $body = @{
        model = $script:cfg.model
        messages = @($messages)
        temperature = 0.8
        max_tokens = $maxTokens
    } | ConvertTo-Json -Depth 12
    $bodyBytes = [Text.Encoding]::UTF8.GetBytes($body)
    $response = Invoke-WebRequest -Uri 'https://api.deepseek.com/chat/completions' -Method Post `
        -Headers @{ Authorization = "Bearer $($script:key)" } -ContentType 'application/json; charset=utf-8' `
        -Body $bodyBytes -UseBasicParsing -TimeoutSec 60
    $stream = $response.RawContentStream
    $stream.Position = 0
    $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::UTF8)
    $parsed = $reader.ReadToEnd() | ConvertFrom-Json
    $reply = [string]$parsed.choices[0].message.content
    if (-not $reply) { throw 'API 返回了空回复。' }
    $tokens = 0
    if ($parsed.usage.total_tokens) { $tokens = [int]$parsed.usage.total_tokens }
    return @{ Reply = $reply; Tokens = $tokens }
}

function Update-SummaryAndLedger([string]$tag, $oldMessages) {
    if (-not $script:key -or -not $oldMessages -or $oldMessages.Count -eq 0) { return }
    $oldText = ($oldMessages | ForEach-Object { "$($_.role): $($_.content)" }) -join "`n"
    $existing = Get-Summary $tag
    $prompt = @"
你是《钢铁雄心4》对局记忆整理器。已有摘要：
$existing

新增对话：
$oldText

请输出严格 JSON（不要 markdown）：
{"summary":"150字以内的新摘要","commitments":[{"side":"玩家或AI","text":"承诺内容","status":"active"}]}
只保留仍然有效的承诺；没有就给空数组。
"@
    try {
        $result = Invoke-ChatApi @(
            @{ role = 'system'; content = '你只输出 JSON，不解释。' },
            @{ role = 'user'; content = $prompt }
        ) 500
        $script:tokens += $result.Tokens
        $match = [regex]::Match($result.Reply, '(?s)\{.*\}')
        if (-not $match.Success) { throw '摘要不是 JSON。' }
        $data = $match.Value | ConvertFrom-Json
        if ($data.summary) { Set-Summary $tag ([string]$data.summary) }
        if ($data.commitments) {
            $oldLedger = @(Get-Ledger $tag)
            $newLedger = New-Object System.Collections.ArrayList
            foreach ($item in $oldLedger) {
                if ($item.status -eq 'active') { [void]$newLedger.Add($item) }
            }
            foreach ($item in @($data.commitments)) {
                if (-not $item.text) { continue }
                $dup = $false
                foreach ($old in $newLedger) { if ($old.text -eq $item.text) { $dup = $true } }
                if (-not $dup) { [void]$newLedger.Add($item) }
            }
            Set-Ledger $tag @($newLedger)
        }
    } catch {
        $fallback = $existing + ' ' + (($oldMessages | ForEach-Object { [string]$_.content }) -join ' ')
        if ($fallback.Length -gt 500) { $fallback = $fallback.Substring(0, 500) }
        Set-Summary $tag $fallback.Trim()
    }
}

function Add-Gradient($control, [Drawing.Color]$from, [Drawing.Color]$to) {
    $control.Tag = @($from, $to)
    $control.Add_Paint({
        param($s, $e)
        $colors = $s.Tag
        if (-not $colors -or $colors.Count -lt 2) { return }
        $rect = $s.ClientRectangle
        if ($rect.Width -le 0 -or $rect.Height -le 0) { return }
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $colors[0], $colors[1], 90)
        $e.Graphics.FillRectangle($brush, $rect)
        $brush.Dispose()
    })
}

function Add-DreamBackground($control, [Drawing.Color]$from, [Drawing.Color]$to) {
    $control.Tag = @($from, $to)
    $control.Add_Paint({
        param($s, $e)
        $colors = $s.Tag
        if (-not $colors -or $colors.Count -lt 2) { return }
        $rect = $s.ClientRectangle
        if ($rect.Width -le 0 -or $rect.Height -le 0) { return }
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $colors[0], $colors[1], 90)
        $e.Graphics.FillRectangle($brush, $rect)
        $brush.Dispose()

        $pink = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(25, 190, 88, 72))
        $lav = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(25, 145, 168, 175))
        $cyan = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(20, 145, 168, 175))
        $e.Graphics.FillEllipse($pink, -90, -70, 300, 300)
        $e.Graphics.FillEllipse($lav, $rect.Width - 170, -60, 320, 320)
        $e.Graphics.FillEllipse($cyan, $rect.Width / 3, $rect.Height - 80, 300, 220)
        $pink.Dispose(); $lav.Dispose(); $cyan.Dispose()

        $starBrush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(110, 231, 224, 211))
        $starFont = New-Object Drawing.Font('Segoe UI Symbol', 10)
        $e.Graphics.DrawString('✦', $starFont, $starBrush, ($rect.Width - 42), 18)
        $e.Graphics.DrawString('✧', $starFont, $starBrush, ($rect.Width - 80), 54)
        $e.Graphics.DrawString('✦', $starFont, $starBrush, 18, ($rect.Height - 44))
        $starBrush.Dispose(); $starFont.Dispose()
    })
}

function Add-SoftBorder($control, [Drawing.Color]$color) {
    $control | Add-Member -NotePropertyName DfyBorderColor -NotePropertyValue $color -Force
    $control.Add_Paint({
        param($s, $e)
        $c = $s.DfyBorderColor
        if ($null -eq $c) { return }
        $pen = New-Object Drawing.Pen($c, 1)
        $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1)
        $pen.Dispose()
    })
}

function Set-Rounded($control, [int]$radius) {
    if ($control.Width -le 1 -or $control.Height -le 1) { return }
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $radius * 2
    $path.AddArc(0, 0, $d, $d, 180, 90)
    $path.AddArc($control.Width - $d - 1, 0, $d, $d, 270, 90)
    $path.AddArc($control.Width - $d - 1, $control.Height - $d - 1, $d, $d, 0, 90)
    $path.AddArc(0, $control.Height - $d - 1, $d, $d, 90, 90)
    $path.CloseFigure()
    $control.Region = New-Object System.Drawing.Region($path)
    $path.Dispose()
}

function New-FlatButton([string]$text, [int]$x, [int]$y, [int]$w, [int]$h, [Drawing.Color]$color) {
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $text
    $button.Location = New-Object Drawing.Point($x, $y)
    $button.Size = New-Object Drawing.Size($w, $h)
    $button.FlatStyle = 'Flat'
    $button.FlatAppearance.BorderSize = 0
    $button.BackColor = $color
    $button.ForeColor = $UiText
    $button.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9)
    $button.Cursor = [Windows.Forms.Cursors]::Hand
    $button.FlatAppearance.MouseOverBackColor = [Drawing.Color]::FromArgb(52, 46, 39)
    $button.FlatAppearance.MouseDownBackColor = [Drawing.Color]::FromArgb(60, 53, 44)
    Set-Rounded $button 8
    return $button
}

function Get-SelectedTag {
    if ($script:advisorMode) {
        if ($script:player -and $script:states.ContainsKey($script:player)) { return $script:player }
        return ''
    }
    $raw = [string]$comboAI.SelectedItem
    if ($raw -match '^([A-Z0-9]{3})') { return $Matches[1] }
    return ''
}

function Add-SystemBubble([string]$message, [Drawing.Color]$color) {
    if (-not $chatPanel) { return }
    $row = New-Object System.Windows.Forms.Panel
    $row.Width = [Math]::Max(200, $chatPanel.ClientSize.Width - 30)
    $row.Height = 28
    $row.BackColor = $UiBg
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $message
    $label.AutoSize = $false
    $label.TextAlign = 'MiddleCenter'
    $label.Dock = 'Fill'
    $label.Font = New-Object Drawing.Font('Microsoft YaHei UI', 8)
    $label.ForeColor = $color
    $label.BackColor = $UiBg
    $row.Controls.Add($label)
    $chatPanel.Controls.Add($row)
    $chatPanel.ScrollControlIntoView($row)
    [Windows.Forms.Application]::DoEvents()
}

function Add-Bubble([string]$speaker, [string]$message, [bool]$isUser, [string]$timestamp = '') {
    if (-not $chatPanel) { return }
    $available = [Math]::Max(360, $chatPanel.ClientSize.Width - 42)
    $maxWidth = [int]($available * 0.72)

    $messageLabel = New-Object System.Windows.Forms.Label
    $messageLabel.Text = $message
    $messageLabel.Font = New-Object Drawing.Font('Microsoft YaHei UI', 10)
    $messageLabel.AutoSize = $true
    $messageLabel.MaximumSize = New-Object Drawing.Size($maxWidth, 0)
    $messageLabel.UseMnemonic = $false
    $preferred = $messageLabel.GetPreferredSize((New-Object Drawing.Size($maxWidth, 2000)))
    $messageLabel.Size = $preferred

    $bubbleWidth = [Math]::Min($maxWidth, [Math]::Max(130, $preferred.Width + 26))
    $bubbleHeight = $preferred.Height + 36

    $bubble = New-Object System.Windows.Forms.Panel
    $bubble.Size = New-Object Drawing.Size($bubbleWidth, $bubbleHeight)
    $bubble.BackColor = if ($isUser) { $UiBubbleUser } else { $UiBubbleAi }
    $borderColor = if ($isUser) { [Drawing.Color]::FromArgb(100, 181, 146, 94) } else { [Drawing.Color]::FromArgb(60, 145, 168, 175) }
    $bubble | Add-Member -NotePropertyName DfyBorderColor -NotePropertyValue $borderColor -Force
    $bubble.Add_Paint({
        param($s, $e)
        $c = $s.DfyBorderColor
        if ($null -eq $c) { return }
        $pen = New-Object Drawing.Pen($c, 1)
        $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1)
        $pen.Dispose()
    })
    Set-Rounded $bubble 16

    $senderLabel = New-Object System.Windows.Forms.Label
    $senderLabel.Text = if ($timestamp) { "$speaker · $timestamp" } else { $speaker }
    $senderLabel.AutoSize = $false
    $senderLabel.Size = New-Object Drawing.Size(($bubbleWidth - 24), 18)
    $senderLabel.Location = New-Object Drawing.Point(12, 6)
    $senderLabel.Font = New-Object Drawing.Font('Microsoft YaHei UI', 8, [Drawing.FontStyle]::Bold)
    $senderLabel.ForeColor = if ($isUser) { [Drawing.Color]::FromArgb(181, 146, 94) } else { [Drawing.Color]::FromArgb(145, 168, 175) }
    $senderLabel.BackColor = $bubble.BackColor
    $bubble.Controls.Add($senderLabel)

    $messageLabel.Location = New-Object Drawing.Point(12, 24)
    $messageLabel.ForeColor = $UiText
    $messageLabel.BackColor = $bubble.BackColor
    $bubble.Controls.Add($messageLabel)

    $row = New-Object System.Windows.Forms.Panel
    $row.Width = [Math]::Max(240, $chatPanel.ClientSize.Width - 30)
    $row.Height = [Math]::Max($bubbleHeight + 8, 40)
    $row.BackColor = $UiBg

    $avatar = New-Object System.Windows.Forms.Panel
    $avatar.Size = New-Object Drawing.Size(30, 30)
    $avatar.Location = if ($isUser) {
        New-Object Drawing.Point([Math]::Max(0, $row.Width - 36), 4)
    } else {
        New-Object Drawing.Point(6, 4)
    }
    $avatar.BackColor = if ($isUser) { [Drawing.Color]::FromArgb(190, 88, 72) } else { [Drawing.Color]::FromArgb(105, 135, 120) }
    Set-Rounded $avatar 15
    $avatarText = New-Object System.Windows.Forms.Label
    $avatarText.Text = if ($speaker.Length -ge 1) { $speaker.Substring(0, 1) } else { '?' }
    $avatarText.TextAlign = 'MiddleCenter'
    $avatarText.Dock = 'Fill'
    $avatarText.Font = New-Object Drawing.Font('Microsoft YaHei UI', 11, [Drawing.FontStyle]::Bold)
    $avatarText.ForeColor = [Drawing.Color]::White
    $avatarText.BackColor = [Drawing.Color]::Transparent
    $avatar.Controls.Add($avatarText)
    $row.Controls.Add($avatar)

    $bubble.Location = if ($isUser) {
        New-Object Drawing.Point([Math]::Max(0, $row.Width - $bubbleWidth - 44), 2)
    } else {
        New-Object Drawing.Point(44, 2)
    }
    $row.Controls.Add($bubble)
    $chatPanel.Controls.Add($row)
    $chatPanel.ScrollControlIntoView($row)
    [Windows.Forms.Application]::DoEvents()
}

function Add-Welcome {
    if (-not $chatPanel) { return }
    if (-not $script:quickButtons) { $script:quickButtons = New-Object System.Collections.ArrayList }
    $advisor = [bool]$script:advisorMode
    $row = New-Object System.Windows.Forms.Panel
    $row.Width = [Math]::Max(400, $chatPanel.ClientSize.Width - 30)
    $row.Height = 212
    $row.BackColor = $UiBg

    $card = New-Object System.Windows.Forms.Panel
    $card.Location = New-Object Drawing.Point(0, 0)
    $card.Size = New-Object Drawing.Size($row.Width, 194)
    $card.BackColor = [Drawing.Color]::FromArgb(38, 34, 29)
    Set-Rounded $card 22
    $row.Controls.Add($card)

    $logoFrame = New-Object System.Windows.Forms.Panel
    $logoFrame.Location = New-Object Drawing.Point(22, 22)
    $logoFrame.Size = New-Object Drawing.Size(58, 58)
    $logoFrame.BackColor = [Drawing.Color]::FromArgb(58, 51, 42)
    Set-Rounded $logoFrame 18
    $card.Controls.Add($logoFrame)

    $welcomeLogo = Join-Path $PSScriptRoot 'assets\whale.png'
    if (Test-Path -LiteralPath $welcomeLogo) {
        $pic = New-Object System.Windows.Forms.PictureBox
        $pic.Image = [Drawing.Image]::FromFile($welcomeLogo)
        $pic.SizeMode = 'Zoom'
        $pic.BackColor = [Drawing.Color]::Transparent
        $pic.Location = New-Object Drawing.Point(4, 4)
        $pic.Size = New-Object Drawing.Size(50, 50)
        $logoFrame.Controls.Add($pic)
    } else {
        $fallback = New-Object System.Windows.Forms.Label
        $fallback.Text = '🐋'
        $fallback.Dock = 'Fill'
        $fallback.TextAlign = 'MiddleCenter'
        $fallback.Font = New-Object Drawing.Font('Segoe UI Emoji', 22)
        $fallback.BackColor = [Drawing.Color]::Transparent
        $logoFrame.Controls.Add($fallback)
    }

    $eyebrow = New-Object System.Windows.Forms.Label
    $eyebrow.Text = 'A  QUIET  WAR  ROOM'
    $eyebrow.Font = New-Object Drawing.Font('Segoe UI', 7, [Drawing.FontStyle]::Bold)
    $eyebrow.ForeColor = [Drawing.Color]::FromArgb(181, 146, 94)
    $eyebrow.Location = New-Object Drawing.Point(96, 20)
    $eyebrow.Size = New-Object Drawing.Size(300, 16)
    $card.Controls.Add($eyebrow)

    $heading = New-Object System.Windows.Forms.Label
    $heading.Text = if ($advisor) { '让大肥鱼当你的参谋' } else { '和 AI 国家谈一局' }
    $heading.Font = New-Object Drawing.Font('Microsoft YaHei UI', 16, [Drawing.FontStyle]::Bold)
    $heading.ForeColor = $UiText
    $heading.Location = New-Object Drawing.Point(94, 36)
    $heading.Size = New-Object Drawing.Size(420, 30)
    $card.Controls.Add($heading)

    $hint = New-Object System.Windows.Forms.Label
    $hint.Text = if ($advisor) { '她看你的国家，给国策、内政、编制和战争建议。' } else { '它会看自己的工厂、师、船和战争状态，也会记住你答应过什么。' }
    $hint.ForeColor = $UiMuted
    $hint.Location = New-Object Drawing.Point(96, 68)
    $hint.Size = New-Object Drawing.Size(460, 22)
    $card.Controls.Add($hint)
    $script:welcomeHeading = $heading
    $script:welcomeHint = $hint

    $spark = New-Object System.Windows.Forms.Label
    $spark.Text = '✦'
    $spark.Font = New-Object Drawing.Font('Segoe UI Symbol', 18)
    $spark.ForeColor = [Drawing.Color]::FromArgb(120, 181, 146, 94)
    $spark.BackColor = [Drawing.Color]::Transparent
    $spark.Location = New-Object Drawing.Point(($row.Width - 54), 18)
    $spark.Size = New-Object Drawing.Size(40, 34)
    $card.Controls.Add($spark)

    $prompts = if ($advisor) {
        @(
            @{ text = '下一步国策'; say = '我接下来该走什么国策？请给优先级、理由和风险。' },
            @{ text = '内政优先级'; say = '我现在建造、科研、生产、编制应该怎么排优先级？' },
            @{ text = '战争风险'; say = '我当前的战争风险和外交方向怎么样？' }
        )
    } else {
        @(
            @{ text = '分析局势'; say = '帮我分析一下当前局势，我接下来该怎么走？' },
            @{ text = '谈结盟'; say = '我们结盟怎么样？你想要什么条件？' },
            @{ text = '施压'; say = '如果你不答应，我会考虑用武力解决。' }
        )
    }
    $script:quickButtons.Clear()
    $x = 22
    foreach ($item in $prompts) {
        $btn = New-FlatButton $item.text $x 118 120 34 ([Drawing.Color]::FromArgb(51, 46, 38))
        $btn.Tag = $item.say
        [void]$script:quickButtons.Add($btn)
        $btn.Add_Click({
            param($s, $e)
            $inputBox.Text = [string]$s.Tag
            Send-Chat
        })
        $card.Controls.Add($btn)
        $x += 130
    }

    $row.Controls.Add($card)
    $chatPanel.Controls.Add($row)
    $chatPanel.ScrollControlIntoView($row)
}

function Render-History {
    if (-not $chatPanel) { return }
    $chatPanel.SuspendLayout()
    $chatPanel.Controls.Clear()
    $tag = Get-SelectedTag
    if (-not $tag -or -not $script:states.ContainsKey($tag)) {
        $gameRunning = [bool](Get-Process hoi4 -ErrorAction SilentlyContinue)
        $modCount = Get-ModLoadCount
        if ($gameRunning -and $modCount -eq 0) {
            Add-SystemBubble '游戏在跑，但这次启动没有加载 mod（Active Mod Count 0）。请保存退出，确认播放集勾选 DaFeiYu HOI4，重新启动游戏，再过一周。' $UiRed
        } elseif ($gameRunning) {
            Add-SystemBubble '游戏在跑，但还没有收到本局国力。过一周，或读一次档再等一周。' $UiMuted
        } else {
            Add-SystemBubble '先启动游戏，选国家开局并过一周；然后在这里选 AI 国家。' $UiMuted
        }
        $chatPanel.ResumeLayout()
        return
    }
    $state = $script:states[$tag]
    $history = Get-Memory $tag
    if ($history.Count -eq 0) {
        Add-Welcome
        $chatPanel.ResumeLayout()
        return
    }
    Add-SystemBubble "这是和 $($state.country) 的本局对话。" $UiMuted
    foreach ($item in ($history | Select-Object -Last 10)) {
        if (-not $item.content) { continue }
        if ($item.role -eq 'user') {
            Add-Bubble '你' ([string]$item.content) $true ([string]$item.time)
        } else {
            Add-Bubble $state.country ([string]$item.content) $false ([string]$item.time)
        }
    }
    $chatPanel.ResumeLayout()
    if ($chatPanel.Controls.Count -gt 0) {
        $chatPanel.ScrollControlIntoView($chatPanel.Controls[$chatPanel.Controls.Count - 1])
    }
}

function Get-Relations([string]$tag) {
    $members = @($script:factionMembers[$tag])
    $guarantees = @($script:guarantees[$tag])
    $guaranteedBy = @($script:guaranteedBy[$tag])
    $enemies = @($script:enemies[$tag])
    return @{
        inFactionWithPlayer = [bool]($script:player -and ($members -contains $script:player))
        guaranteesPlayer = [bool]($script:player -and ($guarantees -contains $script:player))
        guaranteedByPlayer = [bool]($script:player -and ($guaranteedBy -contains $script:player))
        enemies = $enemies.Count
        members = $members
    }
}

function Read-Log {    if (-not (Test-Path -LiteralPath $LogPath)) { return }
    $fs = $null
    try {
        $fs = [IO.File]::Open($LogPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        if ($fs.Length -lt $script:logPos) { $script:logPos = 0 }
        if ($script:logPos -eq 0 -and $fs.Length -gt 2MB) { $script:logPos = $fs.Length - 2MB }
        $fs.Position = $script:logPos
        $reader = New-Object IO.StreamReader($fs, [Text.Encoding]::UTF8)
        $text = $reader.ReadToEnd()
        $script:logPos = $fs.Position
        foreach ($line in ($text -split "`n")) {
            if ($line -match 'DFY\|state\|(.+)$') {
                $payload = $Matches[1].Trim()
                $parts = $payload -split '\|'
                $state = @{}
                foreach ($part in $parts) {
                    if ($part -match '^([^=]+)=(.*)$') { $state[$Matches[1]] = $Matches[2] }
                }
                if ($state.tag) {
                    $script:states[$state.tag] = $state
                    $script:factionMembers[$state.tag] = @()
                    $script:guarantees[$state.tag] = @()
                    $script:guaranteedBy[$state.tag] = @()
                    $script:enemies[$state.tag] = @()
                }
                continue
            }
            if ($line -match 'DFY\|(faction|guarantee|guaranteed_by|enemy|faction_leader)\|(.+)$') {
                $kind = $Matches[1]
                $payload = $Matches[2].Trim()
                $parts = $payload -split '\|'
                $rel = @{}
                foreach ($part in $parts) {
                    if ($part -match '^([^=]+)=(.*)$') { $rel[$Matches[1]] = $Matches[2] }
                }
                if (-not $rel.tag) { continue }
                if ($kind -eq 'faction_leader') {
                    $script:factionLeaders[$rel.tag] = $true
                } elseif ($kind -eq 'faction' -and $rel.member) {
                    $script:factionMembers[$rel.tag] = @(@($script:factionMembers[$rel.tag]) + $rel.member | Select-Object -Unique)
                } elseif ($kind -eq 'guarantee' -and $rel.target) {
                    $script:guarantees[$rel.tag] = @(@($script:guarantees[$rel.tag]) + $rel.target | Select-Object -Unique)
                } elseif ($kind -eq 'guaranteed_by' -and $rel.by) {
                    $script:guaranteedBy[$rel.tag] = @(@($script:guaranteedBy[$rel.tag]) + $rel.by | Select-Object -Unique)
                } elseif ($kind -eq 'enemy' -and $rel.enemy) {
                    $script:enemies[$rel.tag] = @(@($script:enemies[$rel.tag]) + $rel.enemy | Select-Object -Unique)
                }
            }
        }
    } catch {}
    finally { if ($fs) { $fs.Close() } }
}

function Update-StateCard {
    $tag = Get-SelectedTag
    if (-not $tag -or -not $script:states.ContainsKey($tag)) {
        $lblCountry.Text = '等待状态'
        $lblWar.Text = '进游戏并过一周'
        $lblFactories.Text = '民用 —   军工 —   船坞 —'
        $lblArmy.Text = '师 —   人力 —'
        $lblNavy.Text = '舰船 —   飞机 —'
        $lblPolitics.Text = '政治 —   稳定 —   战争支持 —'
        $lblDiplomacy.Text = '科研槽 —   阵营 —'
        $lblChatTitle.Text = if ($script:advisorMode) { '同国参谋' } else { 'AI 国家' }
        $lblChatSub.Text = if ($script:advisorMode) { '大肥鱼看你的国家，给建议' } else { '一个国家的耳语' }
        return
    }
    $s = $script:states[$tag]
    $warText = if ($s.war -eq '1') { '处于战争' } else { '和平' }
    $lblCountry.Text = "$($s.country)  $tag"
    $lblWar.Text = $warText
    $lblWar.ForeColor = if ($s.war -eq '1') { $UiRed } else { $UiGreen }
    $lblFactories.Text = "民用 $($s.civ)   军工 $($s.mil)   船坞 $($s.dock)"
    $lblArmy.Text = "师 $($s.div)   人力 $($s.manpower_k)K"
    $lblNavy.Text = "舰船 $($s.ships)   飞机 $($s.planes)"
    $pp = if ($s.pp) { [double]$s.pp } else { 0 }
    $stab = if ($s.stab) { [double]$s.stab * 100 } else { 0 }
    $ws = if ($s.ws) { [double]$s.ws * 100 } else { 0 }
    $lblPolitics.Text = ("政治 {0:0.0}   稳定 {1:0}%   战争支持 {2:0}%" -f $pp, $stab, $ws)
    $factionText = if ($s.faction -eq '1') { '有' } else { '无' }
    $rel = Get-Relations $tag
    $lblDiplomacy.Text = "科研槽 $($s.res)   阵营 $factionText   敌国 $($rel.enemies)"
    $lblChatTitle.Text = if ($script:advisorMode) { '同国参谋 · ' + $s.country } else { "$($s.country)  ·  $tag" }
    $lblChatSub.Text = if ($script:advisorMode) { '大肥鱼看你的国家，给建议 · ' + $warText } else { "一个国家的耳语 · $warText · 档案已同步" }
    $lblFlag.Text = $tag
    $lblFlag.Visible = $true
    $flag.BackColor = [Drawing.Color]::FromArgb(78, 67, 52)
}

function Update-Controls {
    Read-Log
    $playerChanged = $false
    if (-not $script:cfg.player_override -and (Get-Process hoi4 -ErrorAction SilentlyContinue) -and ((Get-Date) - $script:lastPlayerDetect).TotalSeconds -ge 12) {
        $script:lastPlayerDetect = Get-Date
        $detected = Detect-Player
        if ($detected -and $detected -ne $script:player) {
            $script:player = $detected
            $campaign = Get-CampaignInfo
            $script:campaignKey = $campaign.Key
            $script:campaignTitle = $campaign.Title
            $playerChanged = $true
        }
    }
    if ($script:advisorMode) {
        $tags = if ($script:states.ContainsKey($script:player)) { @($script:player) } else { @() }
    } else {
        $tags = @($script:states.Keys | Where-Object { $_ -ne $script:player } | Sort-Object)
    }
    $comboAI.Enabled = -not $script:advisorMode
    $lblAI.Text = if ($script:advisorMode) { '同国参谋' } else { 'AI 国家' }
    $btnActions.Enabled = -not $script:advisorMode
    $btnAdvisorInfo.Visible = $script:advisorMode
    $items = @($comboAI.Items | ForEach-Object { ([string]$_).Substring(0, 3) })
    if (($tags -join ',') -ne ($items -join ',')) {
        $current = Get-SelectedTag
        $script:loadingCombo = $true
        $comboAI.BeginUpdate()
        $comboAI.Items.Clear()
        foreach ($tag in $tags) {
            $countryName = $script:states[$tag].country
            [void]$comboAI.Items.Add("$tag · $countryName")
        }
        if ($current) {
            foreach ($item in $comboAI.Items) {
                if (([string]$item).StartsWith("$current ")) { $comboAI.SelectedItem = $item; break }
            }
        }
        if (-not $comboAI.SelectedItem -and $tags.Count -gt 0) {
            $preferred = @('ENG', 'FRA', 'SOV', 'USA', 'GER', 'ITA', 'JAP')
            $pick = $tags | Where-Object { $preferred -contains $_ } | Select-Object -First 1
            if (-not $pick) { $pick = $tags[0] }
            foreach ($item in $comboAI.Items) {
                if (([string]$item).StartsWith("$pick ")) { $comboAI.SelectedItem = $item; break }
            }
        }
        $comboAI.EndUpdate()
        $script:loadingCombo = $false
        Render-History
    }

    Update-StateCard
    $selectedTag = Get-SelectedTag
    if ($selectedTag -and $script:states.ContainsKey($selectedTag)) {
        Update-ActionHistory $selectedTag $script:states[$selectedTag]
    }
    $game = [bool](Get-Process hoi4 -ErrorAction SilentlyContinue)
    $lblGame.Text = if ($game) { '● 游戏运行中' } else { '● 游戏未运行' }
    $lblGame.ForeColor = [Drawing.Color]::White
    $lblGame.BackColor = if ($game) { [Drawing.Color]::FromArgb(74, 98, 82) } else { [Drawing.Color]::FromArgb(74, 98, 82) }
    $lblPlayer.Text = "你：$($script:player)" + $(if ($script:cfg.player_override) { ' · 手动' } else { '' })
    $lblCampaign.Text = "本局：$($script:campaignTitle)"
    $lblTokens.Text = "本次会话 tokens：$($script:tokens)"
    if ($playerChanged) { Render-History }
    if ($script:thinking) {
        $dots = '.' * (([int]((Get-Date).Millisecond / 250)) % 4 + 1)
        $lblStatus.Text = "正在思考$dots"
    }
}

function Show-MemoryDialog {
    $tag = Get-SelectedTag
    if (-not $tag) { return }
    $summary = Get-Summary $tag
    if (-not $summary) { $summary = '暂无摘要。聊到 15 轮以上会自动整理。' }
    $ledger = @(Get-Ledger $tag)
    $actions = @(Get-ActionHistory $tag | Select-Object -Last 6)

    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = '本局记忆'
    $dialog.ClientSize = New-Object Drawing.Size(620, 500)
    $dialog.StartPosition = 'CenterParent'
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = $UiBg
    Add-DreamBackground $dialog ([Drawing.Color]::FromArgb(29, 27, 23)) ([Drawing.Color]::FromArgb(20, 19, 17))
    $dialog.ForeColor = $UiText
    $dialog.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "和 $tag 的本局记忆"
    $title.Font = New-Object Drawing.Font('Microsoft YaHei UI', 16, [Drawing.FontStyle]::Bold)
    $title.Location = New-Object Drawing.Point(24, 16)
    $title.Size = New-Object Drawing.Size(560, 32)
    $dialog.Controls.Add($title)

    $label1 = New-Object System.Windows.Forms.Label
    $label1.Text = '摘要'
    $label1.ForeColor = $UiMuted
    $label1.BackColor = [Drawing.Color]::Transparent
    $label1.Location = New-Object Drawing.Point(24, 58)
    $label1.Size = New-Object Drawing.Size(80, 20)
    $dialog.Controls.Add($label1)

    $summaryBox = New-Object System.Windows.Forms.TextBox
    $summaryBox.Text = $summary
    $summaryBox.ReadOnly = $true
    $summaryBox.Multiline = $true
    $summaryBox.ScrollBars = 'Vertical'
    $summaryBox.BackColor = $UiCard
    $summaryBox.ForeColor = $UiText
    $summaryBox.BorderStyle = 'FixedSingle'
    $summaryBox.Location = New-Object Drawing.Point(24, 80)
    $summaryBox.Size = New-Object Drawing.Size(570, 70)
    $summaryBox.TabStop = $false
    $summaryBox.SelectionStart = 0
    $summaryBox.SelectionLength = 0
    $dialog.Controls.Add($summaryBox)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Text = '承诺账本'
    $label2.ForeColor = $UiMuted
    $label2.BackColor = [Drawing.Color]::Transparent
    $label2.Location = New-Object Drawing.Point(24, 162)
    $label2.Size = New-Object Drawing.Size(120, 20)
    $dialog.Controls.Add($label2)

    $ledgerBox = New-Object System.Windows.Forms.ListBox
    $ledgerBox.BackColor = $UiCard
    $ledgerBox.ForeColor = $UiText
    $ledgerBox.BorderStyle = 'FixedSingle'
    $ledgerBox.Location = New-Object Drawing.Point(24, 184)
    $ledgerBox.Size = New-Object Drawing.Size(570, 72)
    $validLedger = @($ledger | Where-Object { $_.text })
    if ($validLedger.Count -eq 0) {
        [void]$ledgerBox.Items.Add('暂无承诺。')
    } else {
        foreach ($item in $validLedger) {
            [void]$ledgerBox.Items.Add("[$($item.status)] $($item.side)：$($item.text)")
        }
    }
    $dialog.Controls.Add($ledgerBox)

    $label3 = New-Object System.Windows.Forms.Label
    $label3.Text = '最近行动'
    $label3.ForeColor = $UiMuted
    $label3.BackColor = [Drawing.Color]::Transparent
    $label3.Location = New-Object Drawing.Point(24, 266)
    $label3.Size = New-Object Drawing.Size(120, 20)
    $dialog.Controls.Add($label3)

    $actionBox = New-Object System.Windows.Forms.ListBox
    $actionBox.BackColor = $UiCard
    $actionBox.ForeColor = $UiText
    $actionBox.BorderStyle = 'FixedSingle'
    $actionBox.Location = New-Object Drawing.Point(24, 288)
    $actionBox.Size = New-Object Drawing.Size(570, 92)
    if ($actions.Count -eq 0) {
        [void]$actionBox.Items.Add('暂无行动。')
    } else {
        foreach ($item in $actions) {
            [void]$actionBox.Items.Add("$($item.time)  $($item.action)  [$($item.status)]")
        }
    }
    $dialog.Controls.Add($actionBox)

    $clear = New-Object System.Windows.Forms.Button
    $clear.Text = '清空本对话'
    $clear.Location = New-Object Drawing.Point(24, 404)
    $clear.Size = New-Object Drawing.Size(120, 36)
    $clear.FlatStyle = 'Flat'
    $clear.BackColor = $UiCard
    $clear.ForeColor = $UiText
    $dialog.Controls.Add($clear)

    $close = New-Object System.Windows.Forms.Button
    $close.Text = '关闭'
    $close.Location = New-Object Drawing.Point(494, 404)
    $close.Size = New-Object Drawing.Size(100, 36)
    $close.FlatStyle = 'Flat'
    $close.BackColor = $UiBlue
    $close.ForeColor = [Drawing.Color]::White
    $close.DialogResult = 'Cancel'
    $dialog.Controls.Add($close)
    $dialog.CancelButton = $close

    $clear.Add_Click({
        if ([Windows.Forms.MessageBox]::Show('清空本对话的摘要、承诺和消息？', '确认', 'YesNo', 'Question') -ne 'Yes') { return }
        Set-Memory $tag @()
        Set-Summary $tag ''
        Set-Ledger $tag @()
        $dialog.Close()
        Render-History
    })

    $close.Add_Click({})
    $dialog.ActiveControl = $close
    [void]$dialog.ShowDialog()
}

function Set-Player([string]$tag, [bool]$manual) {
    if (-not $tag) { return }
    $script:player = $tag
    $script:cfg.player_override = if ($manual) { $tag } else { '' }
    Save-Config $script:cfg
    $campaign = Get-CampaignInfo
    $script:campaignKey = $campaign.Key
    $script:campaignTitle = $campaign.Title
    $script:lastPlayerDetect = Get-Date
    Update-Controls
    Render-History
}

function Show-PlayerDialog {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = '你玩的是哪个国家'
    $dialog.ClientSize = New-Object Drawing.Size(440, 270)
    $dialog.StartPosition = 'CenterParent'
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = $UiBg
    $dialog.ForeColor = $UiText
    $dialog.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9)
    Add-DreamBackground $dialog ([Drawing.Color]::FromArgb(33, 30, 25)) ([Drawing.Color]::FromArgb(20, 19, 17))

    $title = New-Object System.Windows.Forms.Label
    $title.Text = '你实际玩哪个国家？'
    $title.Font = New-Object Drawing.Font('Microsoft YaHei UI', 14, [Drawing.FontStyle]::Bold)
    $title.ForeColor = $UiText
    $title.BackColor = [Drawing.Color]::Transparent
    $title.Location = New-Object Drawing.Point(22, 16)
    $title.Size = New-Object Drawing.Size(390, 30)
    $dialog.Controls.Add($title)

    $hint = New-Object System.Windows.Forms.Label
    $hint.Text = '软件识别错了就手动改；改完会按新玩家国重新分本局记忆。'
    $hint.ForeColor = $UiMuted
    $hint.BackColor = [Drawing.Color]::Transparent
    $hint.Location = New-Object Drawing.Point(24, 50)
    $hint.Size = New-Object Drawing.Size(390, 20)
    $dialog.Controls.Add($hint)

    $combo = New-Object System.Windows.Forms.ComboBox
    $combo.DropDownStyle = 'DropDownList'
    $combo.Font = New-Object Drawing.Font('Microsoft YaHei UI', 10)
    $combo.Location = New-Object Drawing.Point(24, 82)
    $combo.Size = New-Object Drawing.Size(390, 28)
    $tags = @($script:states.Keys) + @('GER', 'ITA', 'ENG', 'FRA', 'SOV', 'USA', 'JAP', 'CHI', 'POL', 'CAN', 'AST', 'RAJ')
    $tags = @($tags | Sort-Object -Unique)
    foreach ($tag in $tags) {
        $name = if ($script:states.ContainsKey($tag)) { $script:states[$tag].country } else { $tag }
        [void]$combo.Items.Add("$tag · $name")
    }
    foreach ($item in $combo.Items) {
        if (([string]$item).StartsWith("$($script:player) ")) { $combo.SelectedItem = $item; break }
    }
    $dialog.Controls.Add($combo)

    $auto = New-Object System.Windows.Forms.Button
    $auto.Text = '自动识别'
    $auto.Location = New-Object Drawing.Point(24, 196)
    $auto.Size = New-Object Drawing.Size(90, 34)
    $auto.FlatStyle = 'Flat'
    $auto.BackColor = $UiCard
    $auto.ForeColor = $UiText
    $dialog.Controls.Add($auto)

    $follow = New-Object System.Windows.Forms.Button
    $follow.Text = '跟随自动'
    $follow.Location = New-Object Drawing.Point(122, 196)
    $follow.Size = New-Object Drawing.Size(90, 34)
    $follow.FlatStyle = 'Flat'
    $follow.BackColor = $UiCard
    $follow.ForeColor = $UiText
    $dialog.Controls.Add($follow)

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = '确定'
    $ok.Location = New-Object Drawing.Point(252, 196)
    $ok.Size = New-Object Drawing.Size(74, 34)
    $ok.FlatStyle = 'Flat'
    $ok.BackColor = $UiBlue
    $ok.ForeColor = [Drawing.Color]::White
    $dialog.Controls.Add($ok)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = '取消'
    $cancel.Location = New-Object Drawing.Point(338, 196)
    $cancel.Size = New-Object Drawing.Size(74, 34)
    $cancel.FlatStyle = 'Flat'
    $cancel.BackColor = $UiCard
    $cancel.ForeColor = $UiText
    $cancel.DialogResult = 'Cancel'
    $dialog.Controls.Add($cancel)
    $dialog.CancelButton = $cancel

    $auto.Add_Click({
        $detected = Detect-Player
        if (-not $detected) {
            [Windows.Forms.MessageBox]::Show('没识别到。等游戏自动存档一次，或直接手动选。', '自动识别')
            return
        }
        foreach ($item in $combo.Items) {
            if (([string]$item).StartsWith("$detected ")) { $combo.SelectedItem = $item; break }
        }
    })

    $follow.Add_Click({
        $detected = Detect-Player
        if (-not $detected) {
            [Windows.Forms.MessageBox]::Show('现在没识别到，先手动选一个。', '跟随自动')
            return
        }
        Set-Player $detected $false
        $dialog.Close()
    })

    $ok.Add_Click({
        $item = [string]$combo.SelectedItem
        if (-not $item) { return }
        $tag = ($item -split ' · ')[0]
        Set-Player $tag $true
        $dialog.Close()
    })

    [void]$dialog.ShowDialog()
}

function Set-HelpContent($box, [string]$text) {
    $box.Clear()
    foreach ($line in ($text -split "`n")) {
        $line = $line.TrimEnd()
        if ($line -match '^## ') {
            $box.SelectionFont = New-Object Drawing.Font('Microsoft YaHei UI', 12, [Drawing.FontStyle]::Bold)
            $box.SelectionColor = [Drawing.Color]::FromArgb(181, 146, 94)
            $box.AppendText($line.Substring(3) + "`n")
        } elseif ($line -match '^· ') {
            $box.SelectionFont = New-Object Drawing.Font('Microsoft YaHei UI', 10)
            $box.SelectionColor = $UiCyan
            $box.AppendText("  $line`n")
        } else {
            $box.SelectionFont = New-Object Drawing.Font('Microsoft YaHei UI', 10)
            $box.SelectionColor = $UiText
            $box.AppendText($line + "`n")
        }
    }
    $box.SelectionStart = 0
    $box.SelectionLength = 0
}

function Show-Help([string]$section = '第一次使用') {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = '帮助与指引'
    $dialog.ClientSize = New-Object Drawing.Size(840, 600)
    $dialog.StartPosition = 'CenterParent'
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = $UiBg
    $dialog.ForeColor = $UiText
    $dialog.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9)
    Add-DreamBackground $dialog ([Drawing.Color]::FromArgb(33, 30, 25)) ([Drawing.Color]::FromArgb(20, 19, 17))

    $headCard = New-Object System.Windows.Forms.Panel
    $headCard.Location = New-Object Drawing.Point(10, 8)
    $headCard.Size = New-Object Drawing.Size(820, 70)
    $headCard.BackColor = [Drawing.Color]::FromArgb(35, 32, 27)
    Set-Rounded $headCard 16
    $dialog.Controls.Add($headCard)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = '使用指引'
    $title.Font = New-Object Drawing.Font('Microsoft YaHei UI', 20, [Drawing.FontStyle]::Bold)
    $title.ForeColor = $UiText
    $title.BackColor = [Drawing.Color]::Transparent
    $title.Location = New-Object Drawing.Point(14, 5)
    $title.Size = New-Object Drawing.Size(220, 36)
    $headCard.Controls.Add($title)

    $ver = New-Object System.Windows.Forms.Label
    $ver.Text = "v$($script:appVersion)  ·  第一次用、指令、行动、记忆、卸载，都在这里"
    $ver.ForeColor = $UiMuted
    $ver.BackColor = [Drawing.Color]::Transparent
    $ver.Location = New-Object Drawing.Point(16, 42)
    $ver.Size = New-Object Drawing.Size(760, 20)
    $headCard.Controls.Add($ver)

    $nav = New-Object System.Windows.Forms.ListBox
    $nav.Location = New-Object Drawing.Point(24, 84)
    $nav.Size = New-Object Drawing.Size(190, 420)
    $nav.BackColor = $UiCard
    $nav.ForeColor = $UiText
    $nav.BorderStyle = 'FixedSingle'
    $nav.Font = New-Object Drawing.Font('Microsoft YaHei UI', 10)
    foreach ($key in $script:helpSections.Keys) { [void]$nav.Items.Add($key) }
    $dialog.Controls.Add($nav)

    $box = New-Object System.Windows.Forms.RichTextBox
    $box.Location = New-Object Drawing.Point(232, 84)
    $box.Size = New-Object Drawing.Size(580, 420)
    $box.BackColor = $UiCard
    $box.ForeColor = $UiText
    $box.BorderStyle = 'None'
    $box.ReadOnly = $true
    $box.WordWrap = $true
    $box.ScrollBars = 'Vertical'
    $box.Font = New-Object Drawing.Font('Microsoft YaHei UI', 10)
    $dialog.Controls.Add($box)

    $nav.Add_SelectedIndexChanged({
        $key = [string]$nav.SelectedItem
        if ($key -and $script:helpSections.Contains($key)) {
            Set-HelpContent $box $script:helpSections[$key]
        }
    })

    $index = 0
    if ($script:helpSections.Contains($section)) { $index = [array]::IndexOf(@($script:helpSections.Keys), $section) }
    $nav.SelectedIndex = $index

    $open = New-Object System.Windows.Forms.Button
    $open.Text = '打开使用说明'
    $open.Location = New-Object Drawing.Point(24, 536)
    $open.Size = New-Object Drawing.Size(120, 36)
    $open.FlatStyle = 'Flat'
    $open.BackColor = $UiCard
    $open.ForeColor = $UiText
    $dialog.Controls.Add($open)

    $diag = New-Object System.Windows.Forms.Button
    $diag.Text = '复制诊断信息'
    $diag.Location = New-Object Drawing.Point(154, 536)
    $diag.Size = New-Object Drawing.Size(120, 36)
    $diag.FlatStyle = 'Flat'
    $diag.BackColor = $UiCard
    $diag.ForeColor = $UiText
    $dialog.Controls.Add($diag)

    $cmd = New-Object System.Windows.Forms.Button
    $cmd.Text = '复制命令示例'
    $cmd.Location = New-Object Drawing.Point(284, 536)
    $cmd.Size = New-Object Drawing.Size(130, 36)
    $cmd.FlatStyle = 'Flat'
    $cmd.BackColor = $UiCard
    $cmd.ForeColor = $UiText
    $dialog.Controls.Add($cmd)

    $close = New-Object System.Windows.Forms.Button
    $close.Text = '关闭'
    $close.Location = New-Object Drawing.Point(710, 536)
    $close.Size = New-Object Drawing.Size(100, 36)
    $close.FlatStyle = 'Flat'
    $close.BackColor = $UiBlue
    $close.ForeColor = [Drawing.Color]::White
    $close.DialogResult = 'Cancel'
    $dialog.Controls.Add($close)
    $dialog.CancelButton = $close

    $open.Add_Click({
        $guide = Join-Path $PSScriptRoot '使用说明.md'
        if (Test-Path -LiteralPath $guide) {
            Start-Process notepad.exe $guide
        } else {
            [Windows.Forms.MessageBox]::Show('使用说明文件不在软件目录，重新安装会带上。', '提示')
        }
    })

    $diag.Add_Click({
        $tag = Get-SelectedTag
        $game = if (Get-Process hoi4 -ErrorAction SilentlyContinue) { 'running' } else { 'stopped' }
        $text = @(
            "DaFeiYuHOI4=$($script:appVersion)",
            "player=$($script:player)",
            "ai=$tag",
            "game=$game",
            "mods=$(Get-ModLoadCount)",
            "log=$LogPath",
            "app=$PSScriptRoot"
        ) -join "`r`n"
        try { Set-Clipboard -Value $text -ErrorAction Stop } catch { [Windows.Forms.Clipboard]::SetText($text) }
        [Windows.Forms.MessageBox]::Show('诊断信息已复制。', '已复制')
    })

    $cmd.Add_Click({
        $example = 'eval_effect ENG = { add_to_faction = GER }'
        try { Set-Clipboard -Value $example -ErrorAction Stop } catch { [Windows.Forms.Clipboard]::SetText($example) }
        [Windows.Forms.MessageBox]::Show("已复制：`r`n$example`r`n`r`n回游戏按 ~，Ctrl+V，回车。", '命令示例')
    })

    [void]$dialog.ShowDialog()
}

function Show-Settings {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = '设置'
    $dialog.ClientSize = New-Object Drawing.Size(480, 300)
    $dialog.StartPosition = 'CenterParent'
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = $UiBg
    Add-DreamBackground $dialog ([Drawing.Color]::FromArgb(29, 27, 23)) ([Drawing.Color]::FromArgb(20, 19, 17))
    $dialog.ForeColor = $UiText
    $dialog.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = '设置'
    $title.Font = New-Object Drawing.Font('Microsoft YaHei UI', 16, [Drawing.FontStyle]::Bold)
    $title.Location = New-Object Drawing.Point(24, 18)
    $title.Size = New-Object Drawing.Size(200, 32)
    $dialog.Controls.Add($title)

    $labelModel = New-Object System.Windows.Forms.Label
    $labelModel.Text = '模型'
    $labelModel.ForeColor = $UiMuted
    $labelModel.Location = New-Object Drawing.Point(24, 70)
    $labelModel.Size = New-Object Drawing.Size(100, 20)
    $dialog.Controls.Add($labelModel)

    $modelBox = New-Object System.Windows.Forms.TextBox
    $modelBox.Text = $script:cfg.model
    $modelBox.Location = New-Object Drawing.Point(24, 92)
    $modelBox.Size = New-Object Drawing.Size(420, 26)
    $modelBox.BackColor = $UiCard2
    $modelBox.ForeColor = $UiText
    $modelBox.BorderStyle = 'FixedSingle'
    $dialog.Controls.Add($modelBox)

    $labelKey = New-Object System.Windows.Forms.Label
    $labelKey.Text = if ($script:key) { 'DeepSeek API Key（留空则不改）' } else { 'DeepSeek API Key' }
    $labelKey.ForeColor = $UiMuted
    $labelKey.Location = New-Object Drawing.Point(24, 134)
    $labelKey.Size = New-Object Drawing.Size(420, 20)
    $dialog.Controls.Add($labelKey)

    $keyBox = New-Object System.Windows.Forms.TextBox
    $keyBox.UseSystemPasswordChar = $true
    $keyBox.Location = New-Object Drawing.Point(24, 156)
    $keyBox.Size = New-Object Drawing.Size(420, 26)
    $keyBox.BackColor = $UiCard2
    $keyBox.ForeColor = $UiText
    $keyBox.BorderStyle = 'FixedSingle'
    $dialog.Controls.Add($keyBox)

    $note = New-Object System.Windows.Forms.Label
    $note.Text = 'Key 只存本机，Windows DPAPI 加密。'
    $note.ForeColor = $UiMuted
    $note.Location = New-Object Drawing.Point(24, 190)
    $note.Size = New-Object Drawing.Size(420, 20)
    $dialog.Controls.Add($note)

    $test = New-Object System.Windows.Forms.Button
    $test.Text = '测试 Key'
    $test.Location = New-Object Drawing.Point(24, 238)
    $test.Size = New-Object Drawing.Size(100, 32)
    $test.FlatStyle = 'Flat'
    $test.BackColor = $UiCard
    $test.ForeColor = $UiText
    $dialog.Controls.Add($test)

    $save = New-Object System.Windows.Forms.Button
    $save.Text = '保存'
    $save.Location = New-Object Drawing.Point(264, 238)
    $save.Size = New-Object Drawing.Size(80, 32)
    $save.DialogResult = 'OK'
    $dialog.Controls.Add($save)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = '取消'
    $cancel.Location = New-Object Drawing.Point(364, 238)
    $cancel.Size = New-Object Drawing.Size(80, 32)
    $cancel.DialogResult = 'Cancel'
    $dialog.Controls.Add($cancel)
    $dialog.AcceptButton = $save
    $dialog.CancelButton = $cancel

    $test.Add_Click({
        $oldKey = $script:key
        try {
            if ($keyBox.Text.Trim()) { $script:key = $keyBox.Text.Trim() }
            if (-not $script:key) { throw 'Key 为空。' }
            $r = Invoke-ChatApi @(@{ role = 'user'; content = '只回复 OK' }) 10
            [Windows.Forms.MessageBox]::Show("Key 可用。测试消耗 $($r.Tokens) tokens。", '测试通过')
        } catch {
            [Windows.Forms.MessageBox]::Show("测试失败：$($_.Exception.Message)", '测试失败')
        } finally {
            $script:key = $oldKey
        }
    })

    if ($dialog.ShowDialog() -eq 'OK') {
        $newModel = $modelBox.Text.Trim()
        if ($newModel) { $script:cfg.model = $newModel }
        if ($keyBox.Text.Trim()) {
            Save-Key $keyBox.Text.Trim()
            $script:key = $keyBox.Text.Trim()
        }
        Save-Config $script:cfg
        $lblStatus.Text = "就绪 · $($script:cfg.model)"
    }
}

function Get-ActionDef([string]$id) {
    return $script:actionDefs[$id]
}

function Get-PlayerFactionLeader {
    if ($script:states.ContainsKey($script:player) -and $script:states[$script:player].faction -ne '1') { return $null }
    foreach ($leader in @($script:factionLeaders.Keys)) {
        if (@($script:factionMembers[$leader]) -contains $script:player) { return $leader }
    }
    return $script:player
}

function Get-FactionLeaderForTag([string]$tag) {
    if ($script:factionLeaders.ContainsKey($tag)) { return $tag }
    foreach ($leader in @($script:factionLeaders.Keys)) {
        if (@($script:factionMembers[$leader]) -contains $tag) { return $leader }
    }
    return $tag
}

function Get-ActionTextControl($dialog) {
    if (-not $dialog) { return $null }
    foreach ($control in $dialog.Controls) {
        if ($control.Name -eq 'DfyActionText') { return $control }
    }
    return $null
}

function Get-ActionCommand([string]$id, [string]$aiTag, [string]$target = '', [string]$amount = '', [string]$text = '') {
    $def = Get-ActionDef $id
    if (-not $def) { return $null }
    if ($def.NeedsPlayer -and (-not $script:player -or $script:player -eq '—')) { return $null }
    if ($def.NeedsText) {
        if (-not $text) { return $null }
        if ($def.TextPattern -and $text -notmatch $def.TextPattern) { return $null }
    }
    $targetTag = $script:player
    if ($def.NeedsTarget) {
        if (-not $target) { $target = if ($def.TargetDefault -eq 'player') { $script:player } else { $def.TargetDefault } }
        $targetTag = ([string]$target).ToUpperInvariant()
        if ($targetTag -notmatch '^[A-Z0-9]{3}$' -or $targetTag -eq $aiTag) { return $null }
    }
    $amountText = ''
    if ($def.NeedsAmount) {
        if (-not $amount) { $amount = [string]$def.DefaultAmount }
        $num = 0.0
        if (-not [double]::TryParse([string]$amount, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$num)) { return $null }
        if ($def.MinAmount -and $num -lt [double]$def.MinAmount) { return $null }
        if ($def.MaxAmount -and $num -gt [double]$def.MaxAmount) { return $null }
        $amountText = $num.ToString('0.######', [Globalization.CultureInfo]::InvariantCulture)
    }
    $command = [string]$def.Command
    $scopePlayer = $script:player
    $scopeAi = $aiTag
    if ($id -eq 'join_faction') {
        $scopePlayer = Get-PlayerFactionLeader
        if (-not $scopePlayer) { return $null }
    }
    if ($id -in @('force_faction', 'player_join_ai_faction')) { $scopeAi = Get-FactionLeaderForTag $aiTag }
    $command = $command.Replace('{0}', $scopeAi).Replace('{1}', [string]$scopePlayer).Replace('{2}', $targetTag).Replace('{3}', $amountText).Replace('{4}', [string]$text)
    if ($command -match '^effect\s+([A-Z0-9]{3})\s+(.+)$') {
        $scopeTag = $matches[1]
        $body = $matches[2].Trim()
        if ($body -notmatch '=') { $body += ' = yes' }
        $command = "eval_effect $scopeTag = { $body }"
    }
    return $command
}

function Get-FocusChoices([string]$tag) {
    if (-not $tag) { return @() }
    if ($script:focusChoiceCache.ContainsKey($tag)) { return $script:focusChoiceCache[$tag] }
    $choices = New-Object System.Collections.ArrayList
    $exe = Find-Hoi4
    if (-not $exe) { $script:focusChoiceCache[$tag] = @(); return @() }
    $root = Split-Path $exe -Parent
    $loc = @{}
    $locDir = Join-Path $root 'localisation\simp_chinese'
    if (Test-Path -LiteralPath $locDir) {
        foreach ($f in (Get-ChildItem $locDir -Filter *.yml -ErrorAction SilentlyContinue)) {
            foreach ($line in (Get-Content $f.FullName -ErrorAction SilentlyContinue)) {
                if ($line -match '^\s*([A-Za-z0-9_.-]+):\d*\s+"(.*)"') { $loc[$Matches[1]] = $Matches[2] }
            }
        }
    }
    $focusDir = Join-Path $root 'common\national_focus'
    if (Test-Path -LiteralPath $focusDir) {
        $seen = @{}
        foreach ($f in (Get-ChildItem $focusDir -Filter *.txt -ErrorAction SilentlyContinue)) {
            $text = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $text) { continue }
            $head = $text.Substring(0, [Math]::Min(3000, $text.Length))
            if ($head -notmatch 'focus_tree\s*=\s*\{' -or $head -notmatch "tag\s*=\s*$tag") { continue }
            foreach ($m in [regex]::Matches($text, "(?m)^\s*id\s*=\s*($tag_[A-Za-z0-9_]+)\s*$")) {
                $id = $m.Groups[1].Value
                if ($seen.ContainsKey($id)) { continue }
                $seen[$id] = $true
                $name = if ($loc.ContainsKey($id)) { $loc[$id] } else { $id }
                [void]$choices.Add([pscustomobject]@{ id = $id; name = $name; display = "$name · $id" })
            }
        }
    }
    $result = @($choices | Sort-Object name)
    $script:focusChoiceCache[$tag] = $result
    return $result
}

function Show-AdvisorContextDialog {
    $ctx = Get-AdvisorContext
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = '参谋资料'
    $dialog.ClientSize = New-Object Drawing.Size(660, 700)
    $dialog.StartPosition = 'CenterParent'
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = $UiBg
    Add-DreamBackground $dialog ([Drawing.Color]::FromArgb(34, 31, 26)) ([Drawing.Color]::FromArgb(20, 19, 17))
    $dialog.ForeColor = $UiText
    $dialog.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = '给大肥鱼的参谋资料'
    $title.Font = New-Object Drawing.Font('Microsoft YaHei UI', 16, [Drawing.FontStyle]::Bold)
    $title.ForeColor = $UiText
    $title.Location = New-Object Drawing.Point(24, 16)
    $title.Size = New-Object Drawing.Size(600, 32)
    $dialog.Controls.Add($title)

    $sub = New-Object System.Windows.Forms.Label
    $sub.Text = '都可以留空；只写一句也行。国策可从本国焦点树下拉，也可手写。'
    $sub.ForeColor = $UiMuted
    $sub.Location = New-Object Drawing.Point(26, 48)
    $sub.Size = New-Object Drawing.Size(600, 20)
    $dialog.Controls.Add($sub)

    $playerState = $script:states[$script:player]
    $playerLine = New-Object System.Windows.Forms.Label
    $playerLine.Text = if ($playerState) { "当前玩家：$($script:player) · $($playerState.country)" } else { "当前玩家：$($script:player)（等待状态）" }
    $playerLine.ForeColor = $UiCyan
    $playerLine.Location = New-Object Drawing.Point(26, 72)
    $playerLine.Size = New-Object Drawing.Size(600, 20)
    $dialog.Controls.Add($playerLine)

    $defs = @(
        @{ key = 'focus'; label = '国策/分支（可下拉，也可手写；可留空）' },
        @{ key = 'research'; label = '科研（可留空）' },
        @{ key = 'construction'; label = '建造（可留空）' },
        @{ key = 'production'; label = '生产（可留空）' },
        @{ key = 'army'; label = '编制/部队（可留空）' },
        @{ key = 'politics'; label = '法律/顾问/政治（可留空）' },
        @{ key = 'goal'; label = '目标/约束（可留空）' }
    )
    $focusChoices = Get-FocusChoices $script:player
    $boxes = @{}
    $y = 104
    foreach ($def in $defs) {
        $lab = New-Object System.Windows.Forms.Label
        $lab.Text = $def.label
        $lab.ForeColor = $UiMuted
        $lab.Location = New-Object Drawing.Point(26, $y)
        $lab.Size = New-Object Drawing.Size(600, 18)
        $dialog.Controls.Add($lab)

        if ($def.key -eq 'focus') {
            $box = New-Object System.Windows.Forms.ComboBox
            $box.DropDownStyle = 'DropDown'
            $box.AutoCompleteMode = 'SuggestAppend'
            $box.AutoCompleteSource = 'ListItems'
            $box.BackColor = $UiCard2
            $box.ForeColor = $UiText
            $box.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9)
            $box.Location = New-Object Drawing.Point(26, ($y + 20))
            $box.Size = New-Object Drawing.Size(600, 26)
            foreach ($choice in $focusChoices) { [void]$box.Items.Add($choice.display) }
            $box.Text = [string]$ctx.focus
            $dialog.Controls.Add($box)
        } else {
            $box = New-Object System.Windows.Forms.TextBox
            $box.Multiline = $true
            $box.ScrollBars = 'Vertical'
            $box.AcceptsReturn = $true
            $box.BackColor = $UiCard2
            $box.ForeColor = $UiText
            $box.BorderStyle = 'FixedSingle'
            $box.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9)
            $box.Location = New-Object Drawing.Point(26, ($y + 20))
            $box.Size = New-Object Drawing.Size(600, 48)
            $box.Text = [string]$ctx.($def.key)
            $dialog.Controls.Add($box)
        }
        $boxes[$def.key] = $box
        $y += 76
    }

    $save = New-Object System.Windows.Forms.Button
    $save.Text = '保存资料'
    $save.Location = New-Object Drawing.Point(24, 650)
    $save.Size = New-Object Drawing.Size(120, 36)
    $save.FlatStyle = 'Flat'
    $save.BackColor = $UiBlue
    $save.ForeColor = [Drawing.Color]::White
    $save.Add_Click({
        $new = @{}
        foreach ($k in $boxes.Keys) { $new[$k] = [string]$boxes[$k].Text.Trim() }
        Save-AdvisorContext ([pscustomobject]$new)
        $lblStatus.Text = '参谋资料已保存，本局对话会使用它。'
        $dialog.Close()
    })
    $dialog.Controls.Add($save)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = '取消'
    $cancel.Location = New-Object Drawing.Point(158, 650)
    $cancel.Size = New-Object Drawing.Size(100, 36)
    $cancel.FlatStyle = 'Flat'
    $cancel.BackColor = $UiCard
    $cancel.ForeColor = $UiText
    $cancel.DialogResult = 'Cancel'
    $dialog.Controls.Add($cancel)
    $dialog.CancelButton = $cancel

    [void]$dialog.ShowDialog()
}

function Show-ActionPicker {
    $tag = Get-SelectedTag
    if (-not $tag) {
        [Windows.Forms.MessageBox]::Show('先在左侧选一个 AI 国家。', '没有 AI 国家')
        return
    }
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = '给 AI 下令'
    $dialog.ClientSize = New-Object Drawing.Size(640, 470)
    $dialog.StartPosition = 'CenterParent'
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = $UiBg
    Add-DreamBackground $dialog ([Drawing.Color]::FromArgb(29, 27, 23)) ([Drawing.Color]::FromArgb(20, 19, 17))
    $dialog.ForeColor = $UiText
    $dialog.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9)
    $dialog.TopMost = $true
    $dialog.Add_Shown({
        $dialog.Activate()
        $dialog.BringToFront()
    })

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "对 $tag 下令"
    $label.Font = New-Object Drawing.Font('Microsoft YaHei UI', 15, [Drawing.FontStyle]::Bold)
    $label.ForeColor = $UiText
    $label.BackColor = [Drawing.Color]::Transparent
    $label.Location = New-Object Drawing.Point(24, 14)
    $label.Size = New-Object Drawing.Size(590, 30)
    $dialog.Controls.Add($label)

    $sub = New-Object System.Windows.Forms.Label
    $sub.Text = '先选类别，再选指令；“常用”只放最常用的 10 条。'
    $sub.ForeColor = $UiMuted
    $sub.BackColor = [Drawing.Color]::Transparent
    $sub.Location = New-Object Drawing.Point(26, 44)
    $sub.Size = New-Object Drawing.Size(590, 20)
    $dialog.Controls.Add($sub)

    $category = New-Object System.Windows.Forms.ComboBox
    $category.DropDownStyle = 'DropDownList'
    $category.Location = New-Object Drawing.Point(24, 76)
    $category.Size = New-Object Drawing.Size(180, 26)
    $category.BackColor = $UiCard2
    $category.ForeColor = $UiText
    $dialog.Controls.Add($category)

    $combo = New-Object System.Windows.Forms.ComboBox
    $combo.DropDownStyle = 'DropDownList'
    $combo.Location = New-Object Drawing.Point(216, 76)
    $combo.Size = New-Object Drawing.Size(398, 26)
    $combo.BackColor = $UiCard2
    $combo.ForeColor = $UiText
    $dialog.Controls.Add($combo)

    $groups = @('常用', '外交', '阵营', '经济', '科研', '政治', '军事', '强制', '对玩家', '国家')
    $idsByGroup = @{}
    $idsByGroup['常用'] = @('join_faction', 'guarantee', 'invest_civ', 'invest_mil', 'research', 'declare_war', 'white_peace', 'player_access', 'gift_equipment', 'gift_pp')
    foreach ($id in $script:actionDefs.Keys) {
        $group = ([string]$script:actionDefs[$id].Category -split ' · ')[0]
        if (-not $idsByGroup.ContainsKey($group)) { $idsByGroup[$group] = @() }
        if ($groups -notcontains $group) { $groups += $group }
        $idsByGroup[$group] += $id
    }
    foreach ($group in $groups) { [void]$category.Items.Add($group) }

    $desc = New-Object System.Windows.Forms.Label
    $desc.Text = ''
    $desc.ForeColor = $UiMuted
    $desc.BackColor = [Drawing.Color]::Transparent
    $desc.Location = New-Object Drawing.Point(24, 112)
    $desc.Size = New-Object Drawing.Size(590, 40)
    $dialog.Controls.Add($desc)

    $risk = New-Object System.Windows.Forms.Label
    $risk.Text = ''
    $risk.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9, [Drawing.FontStyle]::Bold)
    $risk.BackColor = [Drawing.Color]::Transparent
    $risk.Location = New-Object Drawing.Point(24, 154)
    $risk.Size = New-Object Drawing.Size(590, 20)
    $dialog.Controls.Add($risk)

    $targetLabel = New-Object System.Windows.Forms.Label
    $targetLabel.Text = '目标国家'
    $targetLabel.ForeColor = $UiMuted
    $targetLabel.BackColor = [Drawing.Color]::Transparent
    $targetLabel.Location = New-Object Drawing.Point(24, 184)
    $targetLabel.Size = New-Object Drawing.Size(80, 22)
    $dialog.Controls.Add($targetLabel)

    $target = New-Object System.Windows.Forms.ComboBox
    $target.DropDownStyle = 'DropDownList'
    $target.Location = New-Object Drawing.Point(106, 180)
    $target.Size = New-Object Drawing.Size(180, 26)
    $target.BackColor = $UiCard2
    $target.ForeColor = $UiText
    $targetTags = @($script:states.Keys | Where-Object { $_ -ne $tag } | Sort-Object -Unique)
    if ($script:player -and $targetTags -notcontains $script:player) { $targetTags += $script:player }
    foreach ($t in $targetTags) {
        $name = if ($script:states.ContainsKey($t)) { $script:states[$t].country } else { $t }
        [void]$target.Items.Add("$t · $name")
    }
    $dialog.Controls.Add($target)

    $amountLabel = New-Object System.Windows.Forms.Label
    $amountLabel.Text = '数值'
    $amountLabel.ForeColor = $UiMuted
    $amountLabel.BackColor = [Drawing.Color]::Transparent
    $amountLabel.Location = New-Object Drawing.Point(320, 184)
    $amountLabel.Size = New-Object Drawing.Size(50, 22)
    $dialog.Controls.Add($amountLabel)

    $amountBox = New-Object System.Windows.Forms.NumericUpDown
    $amountBox.Location = New-Object Drawing.Point(374, 180)
    $amountBox.Size = New-Object Drawing.Size(120, 26)
    $amountBox.BackColor = $UiCard2
    $amountBox.ForeColor = $UiText
    $amountBox.BorderStyle = 'FixedSingle'
    $dialog.Controls.Add($amountBox)

    $textLabel = New-Object System.Windows.Forms.Label
    $textLabel.Text = '参数'
    $textLabel.ForeColor = $UiMuted
    $textLabel.BackColor = [Drawing.Color]::Transparent
    $textLabel.Location = New-Object Drawing.Point(24, 214)
    $textLabel.Size = New-Object Drawing.Size(100, 22)
    $dialog.Controls.Add($textLabel)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object Drawing.Point(126, 210)
    $textBox.Size = New-Object Drawing.Size(488, 26)
    $textBox.BackColor = $UiCard2
    $textBox.ForeColor = $UiText
    $textBox.BorderStyle = 'FixedSingle'
    $textBox.Font = New-Object Drawing.Font('Consolas', 9)
    $textBox.Name = 'DfyActionText'
    $dialog.Controls.Add($textBox)

    $previewLabel = New-Object System.Windows.Forms.Label
    $previewLabel.Text = '将复制的命令'
    $previewLabel.ForeColor = $UiMuted
    $previewLabel.BackColor = [Drawing.Color]::Transparent
    $previewLabel.Location = New-Object Drawing.Point(24, 256)
    $previewLabel.Size = New-Object Drawing.Size(590, 20)
    $dialog.Controls.Add($previewLabel)

    $preview = New-Object System.Windows.Forms.TextBox
    $preview.ReadOnly = $true
    $preview.Font = New-Object Drawing.Font('Consolas', 9)
    $preview.BackColor = $UiCard2
    $preview.ForeColor = $UiText
    $preview.BorderStyle = 'FixedSingle'
    $preview.Location = New-Object Drawing.Point(24, 278)
    $preview.Size = New-Object Drawing.Size(590, 42)
    $dialog.Controls.Add($preview)

    $go = New-Object System.Windows.Forms.Button
    $go.Text = '生成并复制'
    $go.Location = New-Object Drawing.Point(24, 350)
    $go.Size = New-Object Drawing.Size(120, 38)
    $go.FlatStyle = 'Flat'
    $go.BackColor = $UiBlue
    $go.ForeColor = [Drawing.Color]::White
    $dialog.Controls.Add($go)

    $custom = New-Object System.Windows.Forms.Button
    $custom.Text = '自定义指令'
    $custom.Location = New-Object Drawing.Point(154, 350)
    $custom.Size = New-Object Drawing.Size(120, 38)
    $custom.FlatStyle = 'Flat'
    $custom.BackColor = $UiCard
    $custom.ForeColor = $UiText
    $dialog.Controls.Add($custom)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = '取消'
    $cancel.Location = New-Object Drawing.Point(514, 350)
    $cancel.Size = New-Object Drawing.Size(100, 38)
    $cancel.FlatStyle = 'Flat'
    $cancel.BackColor = $UiCard
    $cancel.ForeColor = $UiText
    $cancel.DialogResult = 'Cancel'
    $dialog.Controls.Add($cancel)
    $dialog.CancelButton = $cancel

    $updateDetail = {
        $ids = @($combo.Tag)
        $index = $combo.SelectedIndex
        if ($index -lt 0 -or $index -ge $ids.Count) { return }
        $id = $ids[$index]
        $def = $script:actionDefs[$id]
        $desc.Text = $def.Desc
        $risk.Text = if ($def.Risk -eq 'extreme') { '极高风险：会永久改变存档，建议先备份' } elseif ($def.Risk -eq 'high') { '高风险：会直接改变外交/战争状态' } elseif ($def.Risk -eq 'medium') { '中风险：会明显增强 AI' } else { '低风险：常规支援' }
        $risk.ForeColor = if ($def.Risk -in @('high', 'extreme')) { $UiRed } elseif ($def.Risk -eq 'medium') { [Drawing.Color]::FromArgb(190, 150, 95) } else { $UiGreen }
        $targetLabel.Visible = [bool]$def.NeedsTarget
        $target.Visible = [bool]$def.NeedsTarget
        $amountLabel.Visible = [bool]$def.NeedsAmount
        $amountBox.Visible = [bool]$def.NeedsAmount
        $textLabel.Visible = [bool]$def.NeedsText
        $tb = Get-ActionTextControl $dialog
        if ($tb) {
            $tb.Visible = [bool]$def.NeedsText
            if ($def.NeedsText) {
                $textLabel.Text = "$($def.TextLabel)  $($def.TextPlaceholder)"
                if ([string]$tb.Text -ne [string]$def.TextDefault) { $tb.Text = [string]$def.TextDefault }
            }
        }
        if ($def.NeedsTarget) {
            $target.SelectedIndex = -1
            $default = if ($def.TargetDefault -eq 'player') { $script:player } else { $def.TargetDefault }
            if ($default -and $default -ne 'none') {
                foreach ($item in $target.Items) {
                    if (([string]$item).StartsWith("$default ")) { $target.SelectedItem = $item; break }
                }
            }
        }
        if ($def.NeedsAmount) {
            $amountBox.DecimalPlaces = if ($def.Decimals) { [int]$def.Decimals } else { 0 }
            $amountBox.Minimum = [decimal]$def.MinAmount
            $amountBox.Maximum = [decimal]$def.MaxAmount
            $amountBox.Value = [decimal]$def.DefaultAmount
        }
        $targetTag = ''
        if ($def.NeedsTarget -and $target.SelectedItem) { $targetTag = (([string]$target.SelectedItem) -split ' · ')[0] }
        $aiState = $script:states[$tag]
        if ($aiState -and $aiState.faction -ne '1' -and $id -in @('force_faction', 'remove_from_faction', 'dismantle_faction', 'rename_faction', 'faction_leader_self')) {
            $desc.Text += ' 注意：当前 AI 不在阵营，这条不会生效。'
        }
        if ($id -eq 'join_faction' -and -not (Get-PlayerFactionLeader)) {
            $desc.Text += ' 注意：你当前不在阵营，无法让 AI 加入你。'
        }
        if ($id -eq 'join_faction') {
            $playerLeader = Get-PlayerFactionLeader
            if ($playerLeader -and $tag -eq $playerLeader) {
                $desc.Text += ' 注意：这个 AI 就是你所在阵营的领袖，不能加入自己。'
            } elseif ($playerLeader -and (@($script:factionMembers[$playerLeader]) -contains $tag)) {
                $desc.Text += ' 注意：这个 AI 已经在你的阵营。'
            }
        }
        if ($id -eq 'force_faction' -and $targetTag -and $script:states[$targetTag] -and $script:states[$targetTag].faction -eq '1') {
            $desc.Text += ' 注意：目标已在阵营，通常不会转入另一个阵营。'
        }
        $amountText = ''
        if ($def.NeedsAmount) { $amountText = $amountBox.Value.ToString([Globalization.CultureInfo]::InvariantCulture) }
        $textValue = if ($def.NeedsText -and $tb) { $tb.Text.Trim() } else { '' }
        $cmd = Get-ActionCommand $id $tag $targetTag $amountText $textValue
        $preview.Text = if ($cmd) { $cmd } else { '（目标、数值或参数不合法）' }
    }

    $updateActions = {
        $group = [string]$category.SelectedItem
        $ids = @($idsByGroup[$group])
        $combo.Tag = $ids
        $combo.BeginUpdate()
        $combo.Items.Clear()
        foreach ($id in $ids) { [void]$combo.Items.Add($script:actionDefs[$id].Name) }
        $combo.EndUpdate()
        if ($ids.Count -gt 0) { $combo.SelectedIndex = 0 }
        & $updateDetail
    }

    $category.Add_SelectedIndexChanged($updateActions)
    $combo.Add_SelectedIndexChanged($updateDetail)
    $target.Add_SelectedIndexChanged($updateDetail)
    $amountBox.Add_ValueChanged($updateDetail)
    $textBox.Add_TextChanged($updateDetail)
    $category.SelectedIndex = 0
    & $updateActions

    $go.Add_Click({
        $ids = @($combo.Tag)
        $index = $combo.SelectedIndex
        if ($index -lt 0 -or $index -ge $ids.Count) { return }
        $id = $ids[$index]
        $def = $script:actionDefs[$id]
        $tb = Get-ActionTextControl $dialog
        $targetTag = ''
        if ($def.NeedsTarget -and $target.SelectedItem) { $targetTag = (([string]$target.SelectedItem) -split ' · ')[0] }
        $amountText = ''
        if ($def.NeedsAmount) { $amountText = $amountBox.Value.ToString([Globalization.CultureInfo]::InvariantCulture) }
        $textValue = if ($def.NeedsText -and $tb) { $tb.Text.Trim() } else { '' }
        $cmd = Get-ActionCommand $id $tag $targetTag $amountText $textValue
        if (-not $cmd) {
            [Windows.Forms.MessageBox]::Show('目标、数值或参数不合法，检查一下。', '无法生成')
            return
        }
        if ($def.Risk -eq 'extreme') {
            $who = if ($targetTag -eq $script:player) { '目标是你自己' } else { "目标是 $targetTag" }
            $answer = [Windows.Forms.MessageBox]::Show("这是极高风险操作：$($def.Name)。`r`n$who。`r`n会永久改变存档，建议先备份。`r`n`r`n还要继续？", '极高风险', 'YesNo', 'Warning')
            if ($answer -ne 'Yes') { return }
        }
        $dialog.Close()
        Show-ActionDialog $id $tag $targetTag $amountText $textValue
    })

    $custom.Add_Click({
        $dialog.Close()
        Show-CustomAction $tag
    })

    [void]$dialog.ShowDialog()
}
function Show-ActionDialog([string]$id, [string]$aiTag, [string]$target = '', [string]$amount = '', [string]$actionText = '') {
    $def = Get-ActionDef $id
    if (-not $def) { return }
    $command = Get-ActionCommand $id $aiTag $target $amount $actionText
    if (-not $command) {
        [Windows.Forms.MessageBox]::Show('这个行动需要先识别出你玩的国家。', '无法生成命令')
        return
    }
    $last = @(Get-ActionHistory $aiTag | Where-Object { $_.action -eq $id } | Select-Object -Last 1)
    if ($last.Count -gt 0) {
        $seconds = ((Get-Date) - [datetime]$last[0].time).TotalSeconds
        if ($seconds -lt 45) {
            $answer = [Windows.Forms.MessageBox]::Show("这个行动 $([int]$seconds) 秒前刚生成过。还要再来一条？", '冷却中', 'YesNo', 'Question')
            if ($answer -ne 'Yes') { return }
        }
    }

    $copied = $false
    try {
        Set-Clipboard -Value $command -ErrorAction Stop
        $copied = $true
    } catch {
        try { [Windows.Forms.Clipboard]::SetText($command); $copied = $true } catch {}
    }
    Add-ActionHistory $aiTag $id $command $script:states[$aiTag]

    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = 'AI 行动'
    $dialog.ClientSize = New-Object Drawing.Size(620, 420)
    $dialog.StartPosition = 'CenterParent'
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = $UiBg
    Add-DreamBackground $dialog ([Drawing.Color]::FromArgb(29, 27, 23)) ([Drawing.Color]::FromArgb(20, 19, 17))
    $dialog.ForeColor = $UiText
    $dialog.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9)
    $dialog.TopMost = $true

    $title = New-Object System.Windows.Forms.Label
    $title.Text = $def.Name
    $title.Font = New-Object Drawing.Font('Microsoft YaHei UI', 17, [Drawing.FontStyle]::Bold)
    $title.ForeColor = $UiText
    $title.Location = New-Object Drawing.Point(24, 16)
    $title.Size = New-Object Drawing.Size(560, 34)
    $dialog.Controls.Add($title)

    $desc = New-Object System.Windows.Forms.Label
    $desc.Text = $def.Desc
    $desc.ForeColor = $UiMuted
    $desc.Location = New-Object Drawing.Point(24, 52)
    $desc.Size = New-Object Drawing.Size(570, 22)
    $dialog.Controls.Add($desc)

    $steps = @(
        @{ n = '1'; t = '回到游戏，按 ~ 打开控制台' },
        @{ n = '2'; t = '按 Ctrl+V 粘贴命令' },
        @{ n = '3'; t = '按回车执行' }
    )
    $y = 86
    foreach ($step in $steps) {
        $panel = New-Object System.Windows.Forms.Panel
        $panel.Location = New-Object Drawing.Point(24, $y)
        $panel.Size = New-Object Drawing.Size(570, 50)
        $panel.BackColor = $UiCard
        Set-Rounded $panel 10
        $dialog.Controls.Add($panel)

        $num = New-Object System.Windows.Forms.Label
        $num.Text = $step.n
        $num.TextAlign = 'MiddleCenter'
        $num.Font = New-Object Drawing.Font('Microsoft YaHei UI', 11, [Drawing.FontStyle]::Bold)
        $num.ForeColor = [Drawing.Color]::White
        $num.BackColor = $UiBlue
        $num.Location = New-Object Drawing.Point(12, 11)
        $num.Size = New-Object Drawing.Size(28, 28)
        Set-Rounded $num 14
        $panel.Controls.Add($num)

        $text = New-Object System.Windows.Forms.Label
        $text.Text = $step.t
        $text.ForeColor = $UiText
        $text.Font = New-Object Drawing.Font('Microsoft YaHei UI', 10)
        $text.Location = New-Object Drawing.Point(54, 15)
        $text.Size = New-Object Drawing.Size(500, 22)
        $panel.Controls.Add($text)
        $y += 58
    }

    $commandBox = New-Object System.Windows.Forms.TextBox
    $commandBox.Text = $command
    $commandBox.ReadOnly = $true
    $commandBox.Font = New-Object Drawing.Font('Consolas', 10)
    $commandBox.BackColor = $UiCard2
    $commandBox.ForeColor = $UiText
    $commandBox.BorderStyle = 'FixedSingle'
    $commandBox.Location = New-Object Drawing.Point(24, 266)
    $commandBox.Size = New-Object Drawing.Size(570, 28)
    $dialog.Controls.Add($commandBox)

    $status = New-Object System.Windows.Forms.Label
    $status.Text = if ($copied) { '已自动复制到剪贴板。回游戏按 ~，直接 Ctrl+V。' } else { '自动复制失败，点“重新复制”。' }
    $status.ForeColor = if ($copied) { $UiGreen } else { $UiRed }
    $status.Location = New-Object Drawing.Point(24, 300)
    $status.Size = New-Object Drawing.Size(570, 20)
    $dialog.Controls.Add($status)

    $recopy = New-Object System.Windows.Forms.Button
    $recopy.Text = '重新复制'
    $recopy.Location = New-Object Drawing.Point(24, 340)
    $recopy.Size = New-Object Drawing.Size(120, 38)
    $recopy.FlatStyle = 'Flat'
    $recopy.BackColor = $UiCard
    $recopy.ForeColor = $UiText
    $dialog.Controls.Add($recopy)

    $done = New-Object System.Windows.Forms.Button
    $done.Text = '我已粘贴'
    $done.Location = New-Object Drawing.Point(300, 340)
    $done.Size = New-Object Drawing.Size(120, 38)
    $done.FlatStyle = 'Flat'
    $done.BackColor = $UiBlue
    $done.ForeColor = [Drawing.Color]::White
    $done.DialogResult = 'OK'
    $dialog.Controls.Add($done)

    $close = New-Object System.Windows.Forms.Button
    $close.Text = '关闭'
    $close.Location = New-Object Drawing.Point(494, 340)
    $close.Size = New-Object Drawing.Size(100, 38)
    $close.FlatStyle = 'Flat'
    $close.BackColor = $UiCard
    $close.ForeColor = $UiText
    $close.DialogResult = 'Cancel'
    $dialog.Controls.Add($close)
    $dialog.CancelButton = $close

    $helpHint = New-Object System.Windows.Forms.Label
    $helpHint.Text = '不会粘贴？关掉后点主界面「帮助」，里面有完整三步说明。'
    $helpHint.ForeColor = $UiMuted
    $helpHint.Location = New-Object Drawing.Point(24, 386)
    $helpHint.Size = New-Object Drawing.Size(560, 18)
    $dialog.Controls.Add($helpHint)

    $recopy.Add_Click({
        try {
            Set-Clipboard -Value $command -ErrorAction Stop
        } catch {
            [Windows.Forms.Clipboard]::SetText($command)
        }
        $status.Text = '已复制。回游戏按 ~，Ctrl+V，回车。'
        $status.ForeColor = $UiGreen
    })

    [void]$dialog.ShowDialog()
}

function Show-CustomAction([string]$aiTag) {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = '自定义指令'
    $dialog.ClientSize = New-Object Drawing.Size(640, 390)
    $dialog.StartPosition = 'CenterParent'
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = $UiBg
    Add-DreamBackground $dialog ([Drawing.Color]::FromArgb(29, 27, 23)) ([Drawing.Color]::FromArgb(20, 19, 17))
    $dialog.ForeColor = $UiText
    $dialog.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "给 $aiTag 写一条控制台命令"
    $title.Font = New-Object Drawing.Font('Microsoft YaHei UI', 15, [Drawing.FontStyle]::Bold)
    $title.ForeColor = $UiText
    $title.BackColor = [Drawing.Color]::Transparent
    $title.Location = New-Object Drawing.Point(24, 14)
    $title.Size = New-Object Drawing.Size(590, 30)
    $dialog.Controls.Add($title)

    $warn = New-Object System.Windows.Forms.Label
    $warn.Text = '高风险：这里可以写任意 effect。只对自己的存档负责；不确定就不要用。'
    $warn.ForeColor = $UiRed
    $warn.BackColor = [Drawing.Color]::Transparent
    $warn.Location = New-Object Drawing.Point(24, 48)
    $warn.Size = New-Object Drawing.Size(590, 20)
    $dialog.Controls.Add($warn)

    $hint = New-Object System.Windows.Forms.Label
    $hint.Text = '推荐 eval_effect {AI} = { ... }；也可以用 add_equipment。'
    $hint.ForeColor = $UiMuted
    $hint.BackColor = [Drawing.Color]::Transparent
    $hint.Location = New-Object Drawing.Point(24, 72)
    $hint.Size = New-Object Drawing.Size(590, 20)
    $dialog.Controls.Add($hint)

    $box = New-Object System.Windows.Forms.TextBox
    $box.Multiline = $true
    $box.ScrollBars = 'Vertical'
    $box.Font = New-Object Drawing.Font('Consolas', 10)
    $box.BackColor = $UiCard2
    $box.ForeColor = $UiText
    $box.BorderStyle = 'FixedSingle'
    $box.Location = New-Object Drawing.Point(24, 100)
    $box.Size = New-Object Drawing.Size(590, 86)
    $box.Text = 'eval_effect {AI} = { add_political_power = 100 }'
    $dialog.Controls.Add($box)

    $status = New-Object System.Windows.Forms.Label
    $status.Text = ''
    $status.ForeColor = $UiGreen
    $status.BackColor = [Drawing.Color]::Transparent
    $status.Location = New-Object Drawing.Point(24, 196)
    $status.Size = New-Object Drawing.Size(590, 20)
    $dialog.Controls.Add($status)

    $copy = New-Object System.Windows.Forms.Button
    $copy.Text = '复制并记录'
    $copy.Location = New-Object Drawing.Point(24, 240)
    $copy.Size = New-Object Drawing.Size(130, 38)
    $copy.FlatStyle = 'Flat'
    $copy.BackColor = $UiBlue
    $copy.ForeColor = [Drawing.Color]::White
    $dialog.Controls.Add($copy)

    $close = New-Object System.Windows.Forms.Button
    $close.Text = '关闭'
    $close.Location = New-Object Drawing.Point(514, 240)
    $close.Size = New-Object Drawing.Size(100, 38)
    $close.FlatStyle = 'Flat'
    $close.BackColor = $UiCard
    $close.ForeColor = $UiText
    $close.DialogResult = 'Cancel'
    $dialog.Controls.Add($close)
    $dialog.CancelButton = $close

    $copy.Add_Click({
        $cmd = $box.Text.Trim()
        if (-not $cmd) { return }
        if ($cmd -notmatch '^(eval_effect|effect|add_equipment|add_latest_equipment)\s') { $cmd = "eval_effect $aiTag = { $cmd }" }
        $cmd = $cmd.Replace('{AI}', $aiTag).Replace('{PLAYER}', [string]$script:player)
        try {
            Set-Clipboard -Value $cmd -ErrorAction Stop
        } catch {
            [Windows.Forms.Clipboard]::SetText($cmd)
        }
        Add-ActionHistory $aiTag 'custom' $cmd $script:states[$aiTag]
        $status.Text = '已复制并记入行动历史。回游戏按 ~，Ctrl+V，回车。'
        $status.ForeColor = $UiGreen
    })

    [void]$dialog.ShowDialog()
}

function Send-Chat {
    if ($script:sending) { return }
    if (-not $script:key) {
        Show-Settings
        if (-not $script:key) { return }
    }
    $tag = Get-SelectedTag
    if (-not $tag -or -not $script:states.ContainsKey($tag)) {
        [Windows.Forms.MessageBox]::Show('还没有该国的状态。先启动游戏，等一周。', '没有状态')
        return
    }
    $message = $inputBox.Text.Trim()
    if (-not $message) { return }
    if ($message -match '^/(下令|order|action)(\s|$)') {
        $inputBox.Clear()
        if ($script:advisorMode) {
            Add-SystemBubble '同国参谋模式只给建议，不生成控制台命令。需要命令时先切回“AI 国家”。' $UiMuted
        } else {
            Show-ActionPicker
        }
        return
    }
    $messageTime = (Get-Date).ToString('HH:mm')
    if ((Get-Memory $tag).Count -eq 0) { $chatPanel.Controls.Clear() }

    $state = $script:states[$tag]
    $war = if ($state.war -eq '1') { '处于战争' } else { '处于和平' }
    $stabPct = [math]::Round([double]$state.stab * 100)
    $wsPct = [math]::Round([double]$state.ws * 100)
    $relForPrompt = Get-Relations $tag
    $summary = Get-Summary $tag
    if (-not $summary) { $summary = '暂无' }
    $ledgerLines = @()
    foreach ($item in @(Get-Ledger $tag)) {
        if ($item.status -eq 'active' -and $item.text) {
            $ledgerLines += "- $($item.side)：$($item.text)"
        }
    }
    $ledgerText = if ($ledgerLines.Count -gt 0) { $ledgerLines -join "`n" } else { '暂无' }
    $aiActionText = ''
    if (-not $script:advisorMode) {
        $aiActionLines = @()
        foreach ($id in $script:actionDefs.Keys) {
            if ($script:actionDefs[$id].AiSuggest) {
                $aiActionLines += "[ACTION:$id] $($script:actionDefs[$id].Name)"
            }
        }
        $aiActionText = $aiActionLines -join "`n"
    }
    if ($script:advisorMode) {
        $contextText = Get-AdvisorContextText
        $system = @"
你是《钢铁雄心4》玩家国家 $($state.country)（$tag）的总参谋/国务顾问，不是敌国，也不是另一个玩家。玩家就是 $($script:player)，本局是「$($script:campaignTitle)」。

已知国力快照：民用工厂 $($state.civ)，军工 $($state.mil)，船坞 $($state.dock)，师 $($state.div)，人力 $($state.manpower_k)K，舰船 $($state.ships)，飞机 $($state.planes)，$war。
政治点 $($state.pp)，稳定度 $stabPct%，战争支持度 $wsPct%，科研槽 $($state.res)，阵营 $(if ($state.faction -eq '1') { '有' } else { '无' })。
本局摘要：$summary
已知承诺：
$ledgerText
玩家补充的国策/内政资料：
$contextText

要求：
- 用中文，以玩家国参谋身份说话，给建议而不是替玩家做决定；
- 只根据已知快照和玩家提供的信息判断，不要编造生产队列、编制、部队位置等没有的数据；
- 信息不足时明确问玩家；
- 优先给 2-4 条可执行的优先级：国策、建造、科研、生产/编制、外交或战争风险；
- 每条说明理由、代价和风险；
- 不要输出 [ACTION] 标记，不要生成控制台命令，除非玩家明确要求“给我命令”；
- 回答控制在 400 字以内。
"@
    } else {
        $system = @"
你是《钢铁雄心4》中由 AI 扮演的 $($state.country)（$tag）决策者。玩家扮演 $($script:player)，本局是「$($script:campaignTitle)」。
当前国力：民用工厂 $($state.civ)，军工 $($state.mil)，船坞 $($state.dock)，师 $($state.div)，人力 $($state.manpower_k)K，舰船 $($state.ships)，飞机 $($state.planes)，$war。
政治点 $($state.pp)，稳定度 $stabPct%，战争支持度 $wsPct%，科研槽 $($state.res)，阵营 $(if ($state.faction -eq '1') { '有' } else { '无' })。
与玩家同阵营：$(if ($relForPrompt.inFactionWithPlayer) { '是' } else { '否' })；保障玩家：$(if ($relForPrompt.guaranteesPlayer) { '是' } else { '否' })；敌国数量：$($relForPrompt.enemies)。
本局摘要：$summary
已知承诺：
$ledgerText
要求：用中文，像真实的国家决策者一样说话；可以谈判、拒绝、提条件、记仇，但不要跳出角色；不要编造数据里没有的精确数字。回答控制在 250 字以内。
如果你明确同意一个具体行动，在回复最后单独一行输出一个标记；只能选一个，不真心同意就不要输出：
$aiActionText
"@
    }
    $history = @(Get-Memory $tag)
    $messages = New-Object System.Collections.ArrayList
    [void]$messages.Add(@{ role = 'system'; content = $system })
    foreach ($item in ($history | Select-Object -Last 8)) {
        if ($item.role -and $item.content) { [void]$messages.Add(@{ role = $item.role; content = $item.content }) }
    }
    [void]$messages.Add(@{ role = 'user'; content = $message })

    $script:sending = $true
    $script:thinking = $true
    $sendButton.Enabled = $false
    $inputBox.Clear()
    Add-Bubble '你' $message $true $messageTime
    $lblStatus.Text = '正在思考...'
    [Windows.Forms.Application]::DoEvents()

    try {
        $result = Invoke-ChatApi @($messages) 700
        $script:tokens += $result.Tokens
        $reply = $result.Reply
        $actionId = $null
        $aiActionPattern = '\[ACTION:(' + (($script:actionDefs.Keys | Where-Object { $script:actionDefs[$_].AiSuggest } | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')\]'
        $actionMatch = [regex]::Match($reply, $aiActionPattern)
        if ($actionMatch.Success -and -not $script:advisorMode) {
            $actionId = $actionMatch.Groups[1].Value
            $reply = ($reply -replace '\s*\[ACTION:[^\]]+\]\s*', '').Trim()
        }
        $speaker = if ($script:advisorMode) { '大肥鱼 · 参谋' } else { $state.country }
        Add-Bubble $speaker $reply $false ((Get-Date).ToString('HH:mm'))
        if ($actionId) {
            $def = Get-ActionDef $actionId
            Add-SystemBubble "AI 同意采取行动：$($def.Name)。点左侧行动按钮生成命令，手动粘贴一次。" $UiCyan
            Show-ActionDialog $actionId $tag
        }
        $historyList = New-Object System.Collections.ArrayList
        foreach ($item in $history) { [void]$historyList.Add($item) }
        [void]$historyList.Add(@{ role = 'user'; content = $message; time = $messageTime })
        [void]$historyList.Add(@{ role = 'assistant'; content = $reply; time = (Get-Date).ToString('HH:mm') })
        if ($historyList.Count -gt 30) {
            $cut = $historyList.Count - 20
            $oldPart = @()
            for ($i = 0; $i -lt $cut; $i++) { $oldPart += $historyList[$i] }
            $recent = @()
            for ($i = $cut; $i -lt $historyList.Count; $i++) { $recent += $historyList[$i] }
            $lblStatus.Text = '整理本局记忆...'
            [Windows.Forms.Application]::DoEvents()
            Update-SummaryAndLedger $tag $oldPart
            Set-Memory $tag $recent
        } else {
            Set-Memory $tag @($historyList)
        }
        $lblTokens.Text = "本次会话 tokens：$($script:tokens)"
        $lblStatus.Text = "就绪 · $($script:cfg.model)"
    } catch {
        Add-SystemBubble ("请求失败：" + $_.Exception.Message) $UiRed
        $lblStatus.Text = '请求失败，检查 Key/余额'
    } finally {
        $script:sending = $false
        $script:thinking = $false
        $sendButton.Enabled = $true
        $inputBox.Focus()
    }
}

$script:states = @{}
$script:factionMembers = @{}
$script:factionLeaders = @{}
$script:guarantees = @{}
$script:guaranteedBy = @{}
$script:enemies = @{}
$script:logPos = 0
$script:advisorMode = $false
$script:focusChoiceCache = @{}
$script:cfg = Read-Config
$script:player = if ($script:cfg.player_override) { [string]$script:cfg.player_override } else { Detect-Player }
if (-not $script:player) { $script:player = 'GER' }
$script:lastPlayerDetect = Get-Date
$script:memory = Load-Memory
$script:key = Read-Key
$campaign = Get-CampaignInfo
$script:campaignKey = $campaign.Key
$script:campaignTitle = $campaign.Title
$script:tokens = 0
$script:sending = $false
$script:thinking = $false
$script:loadingCombo = $false

$form = New-Object System.Windows.Forms.Form
$form.Text = '大肥鱼 HOI4'
$form.ClientSize = New-Object Drawing.Size(1200, 720)
$form.StartPosition = 'Manual'
$form.Location = New-Object Drawing.Point(20, 10)
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = $UiBg
$form.ForeColor = $UiText
$form.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9)
Add-DreamBackground $form ([Drawing.Color]::FromArgb(23, 21, 19)) ([Drawing.Color]::FromArgb(18, 18, 17))

$sidebar = New-Object System.Windows.Forms.Panel
$sidebar.Location = New-Object Drawing.Point(0, 0)
$sidebar.Size = New-Object Drawing.Size(340, 720)
$sidebar.BackColor = $UiSide
Add-DreamBackground $sidebar ([Drawing.Color]::FromArgb(33, 30, 25)) ([Drawing.Color]::FromArgb(20, 19, 17))
$form.Controls.Add($sidebar)

$logoFrame = New-Object System.Windows.Forms.Panel
$logoFrame.Location = New-Object Drawing.Point(18, 14)
$logoFrame.Size = New-Object Drawing.Size(66, 66)
$logoFrame.BackColor = [Drawing.Color]::FromArgb(47, 42, 34)
Set-Rounded $logoFrame 20
$sidebar.Controls.Add($logoFrame)

$logoPath = Join-Path $PSScriptRoot 'assets\whale.png'
if (Test-Path -LiteralPath $logoPath) {
    $logoPic = New-Object System.Windows.Forms.PictureBox
    $logoPic.Image = [Drawing.Image]::FromFile($logoPath)
    $logoPic.SizeMode = 'Zoom'
    $logoPic.BackColor = [Drawing.Color]::Transparent
    $logoPic.Location = New-Object Drawing.Point(4, 4)
    $logoPic.Size = New-Object Drawing.Size(58, 58)
    $logoFrame.Controls.Add($logoPic)
} else {
    $logoFallback = New-Object System.Windows.Forms.Label
    $logoFallback.Text = '鲸'
    $logoFallback.Dock = 'Fill'
    $logoFallback.TextAlign = 'MiddleCenter'
    $logoFallback.Font = New-Object Drawing.Font('Microsoft YaHei UI', 22, [Drawing.FontStyle]::Bold)
    $logoFallback.ForeColor = [Drawing.Color]::FromArgb(181, 146, 94)
    $logoFallback.BackColor = [Drawing.Color]::Transparent
    $logoFrame.Controls.Add($logoFallback)
}

$eyebrow = New-Object System.Windows.Forms.Label
$eyebrow.Text = 'WHALE  &  IRON'
$eyebrow.Font = New-Object Drawing.Font('Segoe UI', 7, [Drawing.FontStyle]::Bold)
$eyebrow.ForeColor = [Drawing.Color]::FromArgb(181, 146, 94)
$eyebrow.BackColor = [Drawing.Color]::Transparent
$eyebrow.Location = New-Object Drawing.Point(94, 12)
$eyebrow.Size = New-Object Drawing.Size(236, 16)
$sidebar.Controls.Add($eyebrow)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = '大肥鱼 HOI4'
$titleLabel.Font = New-Object Drawing.Font('Microsoft YaHei UI', 16, [Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [Drawing.Color]::FromArgb(181, 146, 94)
$titleLabel.BackColor = [Drawing.Color]::Transparent
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object Drawing.Point(92, 30)
$titleLabel.TextAlign = 'MiddleLeft'
$sidebar.Controls.Add($titleLabel)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = '在钢铁与海浪之间，听一个国家说话'
$subtitle.ForeColor = $UiMuted
$subtitle.BackColor = [Drawing.Color]::Transparent
$subtitle.Location = New-Object Drawing.Point(94, 66)
$subtitle.Size = New-Object Drawing.Size(236, 18)
$sidebar.Controls.Add($subtitle)

$accent = New-Object System.Windows.Forms.Panel
$accent.Location = New-Object Drawing.Point(98, 88)
$accent.Size = New-Object Drawing.Size(46, 2)
$accent.BackColor = [Drawing.Color]::FromArgb(181, 146, 94)
$sidebar.Controls.Add($accent)

$lblPlayer = New-Object System.Windows.Forms.Label
$lblPlayer.Text = '你：—'
$lblPlayer.Font = New-Object Drawing.Font('Microsoft YaHei UI', 10, [Drawing.FontStyle]::Bold)
$lblPlayer.ForeColor = $UiText
$lblPlayer.Location = New-Object Drawing.Point(22, 104)
$lblPlayer.Size = New-Object Drawing.Size(120, 22)
$sidebar.Controls.Add($lblPlayer)

$btnPlayer = New-FlatButton '改' 148 100 44 24 $UiCard
$sidebar.Controls.Add($btnPlayer)

$lblGame = New-Object System.Windows.Forms.Label
$lblGame.Text = '● 游戏未运行'
$lblGame.ForeColor = $UiText
$lblGame.BackColor = [Drawing.Color]::FromArgb(74, 98, 82)
$lblGame.TextAlign = 'MiddleCenter'
$lblGame.Location = New-Object Drawing.Point(22, 128)
$lblGame.Size = New-Object Drawing.Size(120, 22)
Set-Rounded $lblGame 8
$sidebar.Controls.Add($lblGame)

$lblAI = New-Object System.Windows.Forms.Label
$lblAI.Text = 'AI 国家'
$lblAI.ForeColor = $UiMuted
$lblAI.Location = New-Object Drawing.Point(22, 166)
$lblAI.Size = New-Object Drawing.Size(250, 20)
$sidebar.Controls.Add($lblAI)

$comboAI = New-Object System.Windows.Forms.ComboBox
$comboAI.DropDownStyle = 'DropDownList'
$comboAI.Location = New-Object Drawing.Point(22, 188)
$comboAI.Size = New-Object Drawing.Size(296, 26)
$comboAI.BackColor = $UiCard2
$comboAI.ForeColor = $UiText
$comboAI.FlatStyle = 'Flat'
$sidebar.Controls.Add($comboAI)

$stateCard = New-Object System.Windows.Forms.Panel
$stateCard.Location = New-Object Drawing.Point(20, 232)
$stateCard.Size = New-Object Drawing.Size(300, 192)
$stateCard.BackColor = $UiCard
Add-Gradient $stateCard ([Drawing.Color]::FromArgb(42, 38, 32)) ([Drawing.Color]::FromArgb(28, 26, 22))
Add-SoftBorder $stateCard ([Drawing.Color]::FromArgb(75, 181, 146, 94))
Set-Rounded $stateCard 18
$sidebar.Controls.Add($stateCard)

$lblCountry = New-Object System.Windows.Forms.Label
$lblCountry.Text = '等待状态'
$lblCountry.Font = New-Object Drawing.Font('Microsoft YaHei UI', 12, [Drawing.FontStyle]::Bold)
$lblCountry.ForeColor = $UiText
$lblCountry.Location = New-Object Drawing.Point(14, 12)
$lblCountry.Size = New-Object Drawing.Size(272, 26)
$stateCard.Controls.Add($lblCountry)

$lblWar = New-Object System.Windows.Forms.Label
$lblWar.Text = '进游戏并过一周'
$lblWar.Font = New-Object Drawing.Font('Microsoft YaHei UI', 8)
$lblWar.ForeColor = $UiMuted
$lblWar.Location = New-Object Drawing.Point(14, 40)
$lblWar.Size = New-Object Drawing.Size(272, 18)
$stateCard.Controls.Add($lblWar)

$lblFactories = New-Object System.Windows.Forms.Label
$lblFactories.Text = '民用 —   军工 —   船坞 —'
$lblFactories.ForeColor = $UiText
$lblFactories.Location = New-Object Drawing.Point(14, 66)
$lblFactories.Size = New-Object Drawing.Size(272, 20)
$stateCard.Controls.Add($lblFactories)

$lblArmy = New-Object System.Windows.Forms.Label
$lblArmy.Text = '师 —   人力 —'
$lblArmy.ForeColor = $UiMuted
$lblArmy.Location = New-Object Drawing.Point(14, 94)
$lblArmy.Size = New-Object Drawing.Size(272, 20)
$stateCard.Controls.Add($lblArmy)

$lblNavy = New-Object System.Windows.Forms.Label
$lblNavy.Text = '舰船 —   飞机 —'
$lblNavy.ForeColor = $UiMuted
$lblNavy.Location = New-Object Drawing.Point(14, 118)
$lblNavy.Size = New-Object Drawing.Size(272, 20)
$stateCard.Controls.Add($lblNavy)

$lblPolitics = New-Object System.Windows.Forms.Label
$lblPolitics.Text = '政治 —   稳定 —   战争支持 —'
$lblPolitics.ForeColor = $UiMuted
$lblPolitics.Location = New-Object Drawing.Point(14, 144)
$lblPolitics.Size = New-Object Drawing.Size(272, 20)
$stateCard.Controls.Add($lblPolitics)

$lblDiplomacy = New-Object System.Windows.Forms.Label
$lblDiplomacy.Text = '科研槽 —   阵营 —'
$lblDiplomacy.ForeColor = $UiMuted
$lblDiplomacy.Location = New-Object Drawing.Point(14, 168)
$lblDiplomacy.Size = New-Object Drawing.Size(272, 20)
$stateCard.Controls.Add($lblDiplomacy)

$btnGame = New-FlatButton '启动游戏' 20 432 125 36 $UiCard
$sidebar.Controls.Add($btnGame)
$btnSettings = New-FlatButton '设置' 155 432 125 36 $UiCard
$sidebar.Controls.Add($btnSettings)
$btnClear = New-FlatButton '清空对话' 20 472 125 36 $UiCard
$sidebar.Controls.Add($btnClear)
$btnActions = New-FlatButton '行动' 155 472 125 36 $UiCard
$sidebar.Controls.Add($btnActions)
$btnMemory = New-FlatButton '记忆' 20 512 125 32 $UiCard
$sidebar.Controls.Add($btnMemory)
$btnHelp = New-FlatButton '帮助' 155 512 125 32 $UiCard
$sidebar.Controls.Add($btnHelp)

$lblCampaign = New-Object System.Windows.Forms.Label
$lblCampaign.Text = '本局：—'
$lblCampaign.ForeColor = $UiMuted
$lblCampaign.Location = New-Object Drawing.Point(22, 550)
$lblCampaign.Size = New-Object Drawing.Size(256, 30)
$sidebar.Controls.Add($lblCampaign)

$lblTokens = New-Object System.Windows.Forms.Label
$lblTokens.Text = '本次会话 tokens：0'
$lblTokens.ForeColor = $UiMuted
$lblTokens.Location = New-Object Drawing.Point(22, 584)
$lblTokens.Size = New-Object Drawing.Size(256, 20)
$sidebar.Controls.Add($lblTokens)

$lblVersion = New-Object System.Windows.Forms.Label
$lblVersion.Text = "v$($script:appVersion) · 独立版"
$lblVersion.ForeColor = [Drawing.Color]::FromArgb(102, 104, 100)
$lblVersion.Location = New-Object Drawing.Point(22, 630)
$lblVersion.Size = New-Object Drawing.Size(256, 20)
$sidebar.Controls.Add($lblVersion)

$flag = New-Object System.Windows.Forms.Panel
$flag.Location = New-Object Drawing.Point(322, 18)
$flag.Size = New-Object Drawing.Size(44, 28)
$flag.BackColor = $UiCard
Set-Rounded $flag 6
$form.Controls.Add($flag)

$lblFlag = New-Object System.Windows.Forms.Label
$lblFlag.Text = 'AI'
$lblFlag.TextAlign = 'MiddleCenter'
$lblFlag.Dock = 'Fill'
$lblFlag.Font = New-Object Drawing.Font('Consolas', 9, [Drawing.FontStyle]::Bold)
$lblFlag.ForeColor = [Drawing.Color]::White
$lblFlag.BackColor = [Drawing.Color]::Transparent
$flag.Controls.Add($lblFlag)

$lblChatTitle = New-Object System.Windows.Forms.Label
$lblChatTitle.Text = 'AI 国家'
$lblChatTitle.Font = New-Object Drawing.Font('Microsoft YaHei UI', 15, [Drawing.FontStyle]::Bold)
$lblChatTitle.ForeColor = $UiText
$lblChatTitle.Location = New-Object Drawing.Point(418, 18)
$lblChatTitle.Size = New-Object Drawing.Size(450, 30)
$form.Controls.Add($lblChatTitle)

$lblChatSub = New-Object System.Windows.Forms.Label
$lblChatSub.Text = '一个国家的耳语'
$lblChatSub.ForeColor = $UiMuted
$lblChatSub.Location = New-Object Drawing.Point(418, 50)
$lblChatSub.Size = New-Object Drawing.Size(480, 20)
$form.Controls.Add($lblChatSub)

$btnCopyChat = New-FlatButton '复制对话' 1074 48 80 26 $UiCard
$form.Controls.Add($btnCopyChat)
$btnCopyChat.BringToFront()

$btnAdvisor = New-FlatButton '同国参谋' 956 48 108 26 $UiCard
$form.Controls.Add($btnAdvisor)
$btnAdvisor.BringToFront()

$btnAdvisorInfo = New-FlatButton '资料' 880 48 64 26 $UiCard
$btnAdvisorInfo.Visible = $false
$form.Controls.Add($btnAdvisorInfo)
$btnAdvisorInfo.BringToFront()
$btnAdvisorInfo.Add_Click({ Show-AdvisorContextDialog })
$btnAdvisor.Add_Click({
    $script:advisorMode = -not $script:advisorMode
    if ($script:advisorMode) {
        $btnAdvisor.Text = '参谋模式：开'
        $btnAdvisor.BackColor = [Drawing.Color]::FromArgb(68, 83, 86)
        $btnAdvisorInfo.Visible = $true
        $lblAI.Text = '同国参谋'
        $lblChatTitle.Text = '同国参谋'
        $lblChatSub.Text = '大肥鱼看你的国家，给建议，不替你操作'
        if ($script:welcomeHeading) { $script:welcomeHeading.Text = '让大肥鱼当你的参谋' }
        if ($script:welcomeHint) { $script:welcomeHint.Text = '她看你的国家，给国策、内政、编制和战争建议。' }
        if ($script:quickButtons.Count -ge 3) {
            $script:quickButtons[0].Text = '下一步国策'
            $script:quickButtons[0].Tag = '我接下来该走什么国策？请给优先级、理由和风险。'
            $script:quickButtons[1].Text = '内政优先级'
            $script:quickButtons[1].Tag = '我现在建造、科研、生产、编制应该怎么排优先级？'
            $script:quickButtons[2].Text = '战争风险'
            $script:quickButtons[2].Tag = '我当前的战争风险和外交方向怎么样？'
        }
        $lblStatus.Text = '同国参谋：基于每周国力给建议，不自动操作。'
    } else {
        $btnAdvisor.Text = '同国参谋'
        $btnAdvisor.BackColor = $UiCard
        $btnAdvisorInfo.Visible = $false
        $lblAI.Text = 'AI 国家'
        $lblChatTitle.Text = 'AI 国家'
        $lblChatSub.Text = '一个国家的耳语'
        if ($script:welcomeHeading) { $script:welcomeHeading.Text = '和 AI 国家谈一局' }
        if ($script:welcomeHint) { $script:welcomeHint.Text = '它会看自己的工厂、师、船和战争状态，也会记住你答应过什么。' }
        if ($script:quickButtons.Count -ge 3) {
            $script:quickButtons[0].Text = '分析局势'
            $script:quickButtons[0].Tag = '帮我分析一下当前局势，我接下来该怎么走？'
            $script:quickButtons[1].Text = '谈结盟'
            $script:quickButtons[1].Tag = '我们结盟怎么样？你想要什么条件？'
            $script:quickButtons[2].Text = '施压'
            $script:quickButtons[2].Tag = '如果你不答应，我会考虑用武力解决。'
        }
        $lblStatus.Text = "就绪 · $($script:cfg.model)"
    }
    $comboAI.Enabled = -not $script:advisorMode
    Update-Controls
    Render-History
})
$btnCopyChat.Add_Click({
    $tag = Get-SelectedTag
    if (-not $tag) { return }
    $lines = @()
    foreach ($item in @(Get-Memory $tag)) {
        if (-not $item.content) { continue }
        $who = if ($item.role -eq 'user') { '你' } else { $tag }
        $lines += "$who $($item.time)：$($item.content)"
    }
    if ($lines.Count -eq 0) { return }
    try { Set-Clipboard -Value ($lines -join "`r`n") -ErrorAction Stop } catch { [Windows.Forms.Clipboard]::SetText(($lines -join "`r`n")) }
    $lblStatus.Text = '当前对话已复制到剪贴板。'
})

$chatPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$chatPanel.Location = New-Object Drawing.Point(358, 80)
$chatPanel.Size = New-Object Drawing.Size(806, 508)
$chatPanel.BackColor = $UiBg
Add-DreamBackground $chatPanel ([Drawing.Color]::FromArgb(30, 27, 23)) ([Drawing.Color]::FromArgb(19, 19, 18))
$chatPanel.AutoScroll = $true
$chatPanel.FlowDirection = 'TopDown'
$chatPanel.WrapContents = $false
$chatPanel.Padding = New-Object System.Windows.Forms.Padding(4)
$form.Controls.Add($chatPanel)

$inputCard = New-Object System.Windows.Forms.Panel
$inputCard.Location = New-Object Drawing.Point(358, 600)
$inputCard.Size = New-Object Drawing.Size(806, 54)
$inputCard.BackColor = $UiCard
Add-SoftBorder $inputCard ([Drawing.Color]::FromArgb(60, 181, 146, 94))
Set-Rounded $inputCard 18
$form.Controls.Add($inputCard)

$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Location = New-Object Drawing.Point(14, 14)
$inputBox.Size = New-Object Drawing.Size(672, 26)
$inputBox.BackColor = $UiCard
$inputBox.ForeColor = $UiText
$inputBox.BorderStyle = 'None'
$inputBox.Font = New-Object Drawing.Font('Microsoft YaHei UI', 10)
$inputCard.Controls.Add($inputBox)

$inputHint = New-Object System.Windows.Forms.Label
$inputHint.Text = '写下一句话… 或输入 /下令 打开指令面板'
$inputHint.ForeColor = $UiMuted
$inputHint.BackColor = $UiCard
$inputHint.Location = New-Object Drawing.Point(16, 16)
$inputHint.Size = New-Object Drawing.Size(420, 20)
$inputHint.Cursor = [Windows.Forms.Cursors]::IBeam
$inputCard.Controls.Add($inputHint)
$inputHint.BringToFront()

$sendButton = New-Object System.Windows.Forms.Button
$sendButton.Text = '寄出'
$sendButton.Location = New-Object Drawing.Point(700, 8)
$sendButton.Size = New-Object Drawing.Size(94, 38)
$sendButton.FlatStyle = 'Flat'
$sendButton.FlatAppearance.BorderSize = 0
$sendButton.BackColor = $UiBlue
$sendButton.ForeColor = [Drawing.Color]::White
$sendButton.Font = New-Object Drawing.Font('Microsoft YaHei UI', 10, [Drawing.FontStyle]::Bold)
$inputCard.Controls.Add($sendButton)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "就绪 · $($script:cfg.model)"
$lblStatus.ForeColor = $UiMuted
$lblStatus.Location = New-Object Drawing.Point(362, 668)
$lblStatus.Size = New-Object Drawing.Size(800, 20)
$form.Controls.Add($lblStatus)

$btnGame.Add_Click({
    $exe = Find-Hoi4
    if (-not $exe) { [Windows.Forms.MessageBox]::Show('没找到 HOI4，请确认 Steam 安装。', '找不到游戏'); return }
    if (Get-Process hoi4 -ErrorAction SilentlyContinue) {
        [Windows.Forms.MessageBox]::Show('HOI4 已经在运行。', '提示')
    } else {
        $steam = $null
        try { $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamExe } catch {}
        if (-not $steam) { $steam = 'C:\Program Files (x86)\Steam\steam.exe' }
        if (Test-Path -LiteralPath $steam) {
            Start-Process -FilePath $steam -ArgumentList '-applaunch 394360 -debug_mode'
            $lblStatus.Text = '已通过 Steam 启动（DLC/创意工坊正常）。'
        } else {
            Start-Process -FilePath $exe -ArgumentList '-debug_mode' -WorkingDirectory (Split-Path $exe)
            $lblStatus.Text = '已直接启动游戏；DLC 可能不加载，建议从 Steam 启动。'
        }
    }
})

$btnSettings.Add_Click({ Show-Settings })
$btnActions.Add_Click({
    try {
        Show-ActionPicker
    } catch {
        $msg = $_.Exception.ToString()
        try { [IO.File]::AppendAllText((Join-Path $env:TEMP 'dfy_action_error.txt'), "`r`n$msg`r`n") } catch {}
        [Windows.Forms.MessageBox]::Show("打开行动失败：`r`n$($_.Exception.Message)", '行动错误')
    }
})
$btnMemory.Add_Click({ Show-MemoryDialog })
$btnHelp.Add_Click({ Show-Help '第一次使用' })
$btnPlayer.Add_Click({ Show-PlayerDialog })
$btnClear.Add_Click({
    $tag = Get-SelectedTag
    if (-not $tag) { return }
    if ([Windows.Forms.MessageBox]::Show("清空与 $tag 的本局对话记忆？", '确认', 'YesNo', 'Question') -ne 'Yes') { return }
    Set-Memory $tag @()
    Render-History
})

$comboAI.Add_SelectedIndexChanged({
    if ($script:loadingCombo) { return }
    $tag = Get-SelectedTag
    if ($tag) {
        $script:cfg.ai = $tag
        Save-Config $script:cfg
        Render-History
        Update-StateCard
    }
})

$sendButton.Add_Click({ Send-Chat })
$inputBox.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq [Windows.Forms.Keys]::Enter) {
        $e.SuppressKeyPress = $true
        Send-Chat
    }
})
$inputBox.Add_TextChanged({
    $inputHint.Visible = ($inputBox.Text.Length -eq 0)
})
$inputHint.Add_Click({ $inputBox.Focus() })

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1500
$timer.Add_Tick({ Update-Controls })
$form.Add_Shown({
    if (-not $script:key) {
        Show-Settings
        if (-not $script:key) {
            [Windows.Forms.MessageBox]::Show('没有 API Key，可以查看状态，但暂时不能聊天。点设置随时补。', '提示')
        }
    }
    if ($script:cfg.help_seen -ne $script:appVersion) {
        $helpSection = if ($script:cfg.help_seen) { '本版更新' } else { '第一次使用' }
        Show-Help $helpSection
        $script:cfg.help_seen = $script:appVersion
        Save-Config $script:cfg
    }
    Update-Controls
    Render-History
    $timer.Start()
})
$form.Add_FormClosed({ $timer.Stop() })

[void]$form.ShowDialog()
