# DaFeiYu HOI4 agent loop: one-week planning, order file generation.
# P1: manual "托管一周" tick. No chat-path changes, no keyboard simulation.

$script:AgentFile = Join-Path $AppData 'agent.json'
$script:AgentLog = Join-Path $AppData 'agent.log'
$script:agentStore = $null

function Get-AgentKey([string]$tag) {
    return "$script:campaignKey|$tag"
}

function Get-AgentStore {
    if ($script:agentStore) { return $script:agentStore }
    $store = @{}
    if (Test-Path -LiteralPath $script:AgentFile) {
        try {
            $data = Get-Content -LiteralPath $script:AgentFile -Raw | ConvertFrom-Json
            if ($data) {
                foreach ($p in $data.PSObject.Properties) { $store[$p.Name] = $p.Value }
            }
        } catch {}
    }
    $script:agentStore = $store
    return $store
}

function Get-AgentNotes([string]$tag) {
    $store = Get-AgentStore
    $key = Get-AgentKey $tag
    if ($store.ContainsKey($key) -and $store[$key].notes) { return [string]$store[$key].notes }
    return ''
}

function Get-AgentGoal([string]$tag) {
    $store = Get-AgentStore
    $key = Get-AgentKey $tag
    if ($store.ContainsKey($key) -and $store[$key].goal) { return [string]$store[$key].goal }
    return ''
}

function Get-AgentLastFocus([string]$tag) {
    $store = Get-AgentStore
    $key = Get-AgentKey $tag
    if ($store.ContainsKey($key) -and $store[$key].focus) { return [string]$store[$key].focus }
    return ''
}

function Get-AgentGoalFromChat([string]$tag) {
    $history = @(Get-Memory $tag)
    $lastUser = $history | Where-Object { $_.role -eq 'user' -and $_.content } | Select-Object -Last 1
    if ($lastUser) { return ([string]$lastUser.content).Trim() }
    return ''
}

function Set-AgentRecord([string]$tag, [string]$notes, $actions, [string]$goal = '', [string]$focus = '') {
    $store = Get-AgentStore
    $store[(Get-AgentKey $tag)] = [pscustomobject]@{
        notes = $notes
        goal = $goal
        focus = $focus
        week = 0
        updated = (Get-Date).ToString('s')
        actions = @($actions)
    }
    $script:agentStore = $store
    try { $store | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $script:AgentFile -Encoding UTF8 } catch {}
}

function Get-AgentStateText([string]$tag) {
    $s = $script:states[$tag]
    if (-not $s) { return '' }
    $war = if ($s.war -eq '1') { '处于战争' } else { '和平' }
    $stab = [math]::Round([double]$s.stab * 100)
    $ws = [math]::Round([double]$s.ws * 100)
    $rel = Get-Relations $tag
    $enemy = if ($rel.enemies -gt 0) { "敌国 $($rel.enemies) 个" } else { '无敌国' }
    return @"
国家：$($s.country)（$tag）；玩家：$($script:player)
状态：$war；政治点 $($s.pp)；稳定 $stab%；战争支持 $ws%；科研槽 $($s.res)
工业：民用 $($s.civ)；军工 $($s.mil)；船坞 $($s.dock)
军队：师 $($s.div)；人力 $($s.manpower_k)K；舰船 $($s.ships)；飞机 $($s.planes)
外交：阵营 $(if ($s.faction -eq '1') { '有' } else { '无' })；$enemy；保障玩家 $(if ($rel.guaranteesPlayer) { '是' } else { '否' })
"@
}

function Get-AgentFocusList([string]$tag) {
    $choices = @(Get-FocusChoices $tag)
    if ($choices.Count -eq 0) { return '' }
    $rows = @()
    foreach ($c in $choices) { $rows += "- $($c.id) | $($c.name)" }
    return ($rows -join "`n")
}

function Get-AgentTemplateDefs {
    return @{
        inf20 = [pscustomobject]@{
            id = 'inf20'; name = 'DFY 步兵师'; label = 'DFY 步兵师（7步兵+2炮兵）'
            regiments = @('infantry','infantry','infantry','infantry','infantry','infantry','infantry','artillery','artillery')
            support = @('engineer','artillery')
        }
        marine20 = [pscustomobject]@{
            id = 'marine20'; name = 'DFY 海军陆战队'; label = 'DFY 海军陆战队（7陆战+2炮兵）'
            regiments = @('marines','marines','marines','marines','marines','marines','marines','artillery','artillery')
            support = @('engineer','artillery')
        }
        armor20 = [pscustomobject]@{
            id = 'armor20'; name = 'DFY 装甲师'; label = 'DFY 装甲师（6坦克+4摩托化）'
            regiments = @('tank','tank','tank','tank','tank','tank','motorized','motorized','motorized','motorized')
            support = @('engineer','maintenance')
        }
    }
}

function Get-AgentTemplateCommand([string]$tag, [string]$templateId) {
    $defs = Get-AgentTemplateDefs
    if (-not $defs.ContainsKey($templateId)) { return '' }
    $d = $defs[$templateId]
    $regs = @()
    $i = 0
    foreach ($unit in $d.regiments) {
        $x = [int]([math]::Floor($i / 5))
        $y = $i % 5
        $regs += "$unit = { x = $x y = $y }"
        $i++
    }
    $sup = @()
    $i = 0
    foreach ($unit in $d.support) {
        $sup += "$unit = { x = 0 y = $i }"
        $i++
    }
    return "eval_effect $tag = { division_template = { name = `"$($d.name)`" is_locked = no priority = 1 regiments = { $($regs -join ' ') } support = { $($sup -join ' ') } } }"
}

function Get-AgentTemplateList {
    $rows = @()
    foreach ($d in (Get-AgentTemplateDefs).Values) { $rows += "- $($d.id) | $($d.label) | 只添加编制模板，不训练" }
    return ($rows -join "`n")
}

function Get-LocalAgentPlan([string]$tag, [bool]$forPlayer, [string]$goal) {
    $s = $script:states[$tag]
    if (-not $s) { return $null }
    if (-not $goal) { $goal = Get-AgentGoalFromChat $tag }
    if (-not $goal) { $goal = '稳住建制，优先补国内短板' }
    $lower = $goal.ToLowerInvariant()
    $lastFocus = Get-AgentLastFocus $tag
    $focusId = ''
    $focusName = ''
    $choices = @(Get-FocusChoices $tag)
    if ($choices.Count -gt 0) {
        $keywords = @()
        if ($lower -match '海|navy|sea|地中海|制海|舰队') { $keywords += 'nav|sea|maritime|mediterranean|ship|fleet|海|地中海|舰队' }
        if ($lower -match '工业|工厂|建造|经济|industry|factory') { $keywords += 'industr|construction|factory|infra|工业|建造|工厂' }
        if ($lower -match '陆军|装甲|坦克|防守|军队|army|defen') { $keywords += 'army|infantry|armor|tank|defen|军事|陆军|装甲|防御' }
        if ($lower -match '政治|稳定|支持|politic|stabil') { $keywords += 'politic|stabil|propaganda|政治|稳定' }
        $best = $null
        $bestScore = -1
        foreach ($c in $choices) {
            if ($c.id -eq $lastFocus) { continue }
            $hay = "$($c.id) $($c.name) $($c.display)"
            $score = 0
            foreach ($kw in $keywords) { if ($hay -match $kw) { $score += 10 } }
            if ($score -gt $bestScore) { $best = $c; $bestScore = $score }
        }
        if ($best) { $focusId = [string]$best.id; $focusName = [string]$best.name }
    }

    $actions = New-Object System.Collections.ArrayList
    $seen = @{}
    $recent = @(Get-AgentRecentActions $tag)
    $add = {
        param($id, $why)
        if ($seen.ContainsKey($id)) { return }
        if (-not $script:actionDefs.Contains($id)) { return }
        if ($id -like 'invest_*' -and $recent -contains $id) { return }
        $seen[$id] = $true
        [void]$actions.Add([pscustomobject]@{ id = $id; target = ''; amount = $null; text = ''; reason = $why })
    }
    $pp = if ($s.pp) { [double]$s.pp } else { 0 }
    $stab = if ($s.stab) { [double]$s.stab } else { 0 }
    $ws = if ($s.ws) { [double]$s.ws } else { 0 }
    if ($pp -lt 150) { & $add 'boost_pp' '政治点偏低，先保留决策空间' }
    if ($stab -lt 0.6) { & $add 'boost_stability' '稳定度偏低，先压国内风险' }
    if ($lower -match '海|navy|sea|地中海|制海|舰队') {
        & $add 'navy_xp' '愿景是海权，先积累海军经验'
        & $add 'invest_dock' '扩建船坞，支撑舰队'
        & $add 'boost_fuel' '舰队出动需要燃料'
    } elseif ($lower -match '工业|工厂|建造|经济|industry|factory') {
        & $add 'invest_civ' '扩建民用工业'
        & $add 'research' '补科研槽'
    } elseif ($lower -match '陆军|装甲|坦克|防守|军队|army|defen') {
        & $add 'army_xp' '陆军经验支撑编制与战术'
        & $add 'invest_mil' '扩建军工'
        & $add 'boost_manpower' '补充人力'
    } else {
        & $add 'invest_civ' '先补经济基础'
        & $add 'boost_pp' '保留政治点'
    }
    if ($ws -lt 0.5 -and $s.war -eq '1') { & $add 'boost_war_support' '战争支持度低，先稳动员' }
    if ($actions.Count -eq 0) { & $add 'invest_civ' '无更优动作时补经济' }

    $brief = @()
    if ($focusName) { $brief += "国策优先：$focusName" }
    foreach ($a in $actions) {
        if ($brief.Count -ge 3) { break }
        $brief += "$($script:actionDefs[$a.id].Name)：$($a.reason)"
    }
    $actionCount = $actions.Count
    $report = if ($focusName) { "本地规划：$focusName + $actionCount 项" } else { "本地规划：$actionCount 项" }
    $notes = "本局愿景：$goal`n本周重点：$($brief -join '；')"
    return [pscustomobject]@{
        report = $report
        goal = $goal
        brief = @($brief)
        focus = $focusId
        notes = $notes
        actions = @($actions)
    }
}

function Get-AgentActionList([bool]$forPlayer = $false) {
    $rows = @()
    foreach ($id in $script:actionDefs.Keys) {
        $d = $script:actionDefs[$id]
        if (-not $d.AiSuggest) { continue }
        if ($d.Risk -in @('high', 'extreme')) { continue }
        if ($forPlayer) {
            if ($d.Category -like '对玩家*') { continue }
            if ($d.NeedsPlayer) { continue }
            if ($d.Category -like '外交*') { continue }
        }
        $args = @()
        if ($d.NeedsTarget) { $args += 'target=国家代码' }
        if ($d.NeedsAmount) { $args += "amount=$($d.DefaultAmount)（默认）" }
        if ($d.NeedsText) { $args += 'text=参数' }
        $argsText = if ($args.Count) { '；' + ($args -join '，') } else { '' }
        $rows += "- $id | $($d.Name) | $($d.Desc)$argsText"
    }
    return ($rows -join "`n")
}

function Write-AgentOrders($commands) {
    $paths = @()
    $exe = Find-Hoi4
    if ($exe) {
        $gameRoot = Split-Path $exe -Parent
        if ($gameRoot) { $paths += (Join-Path $gameRoot 'dfy_orders.txt') }
    }
    if ($script:DocsRoot) { $paths += (Join-Path $script:DocsRoot 'dfy_orders.txt') }
    $paths = @($paths | Select-Object -Unique)
    $written = @()
    foreach ($p in $paths) {
        try {
            [IO.File]::WriteAllLines($p, @($commands), (New-Object Text.UTF8Encoding($false)))
            $written += $p
        } catch {}
    }
    return @($written)
}

function Get-AgentChatIntent([string]$tag) {
    $history = @(Get-Memory $tag)
    if ($history.Count -eq 0) { return '暂无最近对话。' }
    $recent = $history | Select-Object -Last 6
    $lines = @()
    foreach ($m in $recent) {
        $who = if ($m.role -eq 'user') { '玩家' } else { '大肥鱼' }
        $text = ([string]$m.content).Trim()
        if ($text.Length -gt 260) { $text = $text.Substring(0, 260) + '...' }
        if ($text) { $lines += "$who：$text" }
    }
    if ($lines.Count -eq 0) { return '暂无最近对话。' }
    return ($lines -join "`n")
}

function Get-AgentRecentActions([string]$tag) {
    $store = Get-AgentStore
    $key = Get-AgentKey $tag
    if (-not $store.ContainsKey($key)) { return @() }
    return @($store[$key].actions | ForEach-Object { [string]$_.id })
}

$script:agentAutoTag = ''
$script:agentAutoDate = ''
$script:agentAutoLast = [datetime]::MinValue
$script:agentRunning = $false

function Invoke-AgentAutoTick {
    if ($script:agentRunning) { return }
    if ($script:thinking) { return }
    if ($script:advisorMode) {
        if (-not $script:cfg.auto_player) { return }
    } else {
        if (-not $script:cfg.auto_agent) { return }
    }
    if (((Get-Date) - $script:agentAutoLast).TotalSeconds -lt 25) { return }
    if (-not $script:key) { return }
    $tag = Get-SelectedTag
    if (-not $tag -or -not $script:states.ContainsKey($tag)) { return }
    if (-not (Test-DfyHoi4DebugMode)) { return }
    $date = [string]$script:states[$tag].dateText
    if (-not $date) { return }
    if ($tag -ne $script:agentAutoTag) {
        $script:agentAutoTag = $tag
        $script:agentAutoDate = $date
        return
    }
    if ($date -eq $script:agentAutoDate) { return }
    $script:agentAutoDate = $date
    $script:agentAutoLast = Get-Date
    $script:agentRunning = $true
    try {
        Invoke-AgentWeek
    } catch {
        Add-SystemBubble ("自动托管失败：" + $_.Exception.Message) $UiRed
    } finally {
        $script:agentRunning = $false
    }
}

function Invoke-AgentWeek {
    if (-not $script:key) {
        Show-Settings
        if (-not $script:key) { return }
    }
    if ($script:advisorMode) {
        $tag = $script:player
    } else {
        $tag = Get-SelectedTag
    }
    if (-not $tag -or -not $script:states.ContainsKey($tag)) {
        [Windows.Forms.MessageBox]::Show('还没有国家状态。先启动游戏，等一周。', '没有状态')
        return
    }
    $forPlayer = [bool]$script:advisorMode
    $weekTitle = if ($forPlayer) { '托管玩家一周' } else { '托管一周' }
    $stateDate = [string]$script:states[$tag].dateText
    $script:agentAutoLast = Get-Date
    $allowed = Get-AgentActionList $forPlayer
    $focusList = Get-AgentFocusList $tag
    $templateList = if ($script:cfg.templates_enabled) { Get-AgentTemplateList } else { '（模板功能未启用：当前版本运行时编译未通过）' }
    $notes = Get-AgentNotes $tag
    if (-not $notes) { $notes = '暂无长期笔记。' }
    $goal = Get-AgentGoal $tag
    if (-not $goal) { $goal = '暂无明确愿景；先问玩家想把国家带到哪里。' }
    $recent = @(Get-AgentRecentActions $tag)
    $recentText = if ($recent.Count) { $recent -join '、' } else { '无' }
    $stateText = Get-AgentStateText $tag
    $intent = Get-AgentChatIntent $tag
    $advisorContext = if ($forPlayer) { [string](Get-AdvisorContextText) } else { '' }
    $persona = if ($forPlayer) {
        "你是大肥鱼，$tag 的参谋长。玩家已授权你托管本国一周。你要按玩家最近对话和资料，为这个国家做下一周计划；不能选对玩家送礼/邀请阵营/保障玩家这类对外援助动作，也不能做高风险强制外交。"
    } else {
        "你是《钢铁雄心4》里正在玩 $tag 的玩家，不是外交官。玩家控制另一个国家，和你同局。你要为下一周做决定，优先配合玩家、稳住自己的国家和战争目标。"
    }
    $prompt = @"
$persona
本局愿景（玩家预想的未来；从最近对话更新，没有新目标就保留旧愿景）：
$goal
当前状态（第 N 周开始时的快照，不是实时）：
$stateText
长期笔记：
$notes
上一轮已用动作：$recentText
玩家资料：
$advisorContext

最近对话（玩家意愿；优先按这里的方向做事，但不要越权）：
$intent

只能从下面动作中选，不能编造动作：
$allowed

国策候选（只能选一个；id 或准确名称都行；没有合适就留空）：
$focusList

编制模板候选（可选一个；只添加模板，不训练；不需要就留空）：
$templateList

输出严格 JSON，不要 markdown：
{"report":"一句话说明本周计划","goal":"更新后的本局愿景（从玩家对话提炼；没有变化就保留旧愿景）","brief":["本周第一件事","第二件事","第三件事"],"focus":"国策id或准确名称，可为空","template":"模板id，可为空","notes":"更新后的长期笔记（战略目标/承诺/当前重点）","actions":[{"id":"动作id","target":"目标国家代码，可为空","amount":1,"text":"文本参数，可为空","reason":"为什么"}]}

规则：
- report 只一句话；brief 最多 3 条，写具体动作，不复述全部数据；
- 如果愿景要求走某条线，优先从国策候选里选一个匹配的 focus；
- 没有合适国策就 focus 留空；
- 编制模板只选一个，且只在真的需要新建模板时选；不要每周重复；
- actions 最多 6 个；
- 只能选上面列出的动作；
- 需要 target 的必须填真实国家代码；需要 amount 的填整数；需要 text 的按动作要求填；
- 不要选高风险/强制动作；
- 不要重复同一个动作刷次数；
- 上一轮已用的 invest_* 本轮不要再选，换别的动作；
- 你不自动执行；玩家会运行订单文件。
"@
    $messages = @(
        @{ role = 'system'; content = '你只输出严格 JSON，不解释。' },
        @{ role = 'user'; content = $prompt }
    )
    $lblStatus.Text = "$weekTitle：正在规划..."
    [Windows.Forms.Application]::DoEvents()
    try {
        if ($script:cfg.local_plan) {
            $data = Get-LocalAgentPlan $tag $forPlayer $goal
            if (-not $data) { throw '本地规划没有可用状态。' }
            $result = @{ Tokens = 0 }
            $lblStatus.Text = "$weekTitle：本地规则规划（0 tokens）"
        } else {
            $result = Invoke-ChatApi $messages 900
            $script:tokens += $result.Tokens
            $match = [regex]::Match([string]$result.Reply, '(?s)\{.*\}')
            if (-not $match.Success) { throw '规划结果不是 JSON。' }
            $data = $match.Value | ConvertFrom-Json
        }
        $orders = New-Object System.Collections.ArrayList
        $seen = @{}
        $focusNote = ''
        $templateNote = ''
        $templateValue = [string]$data.template
        if ($script:cfg.templates_enabled -and $templateValue -and $recent -notcontains 'agent_template') {
            $templateCmd = Get-AgentTemplateCommand $tag $templateValue
            if ($templateCmd) {
                [void]$orders.Add([pscustomobject]@{
                    id = 'agent_template'
                    command = $templateCmd
                    reason = "编制模板：$templateValue"
                })
                $seen['agent_template'] = $true
                $templateNote = "编制模板：$templateValue"
            }
        }
        $focusValue = [string]$data.focus
        if ($focusValue) {
            $focusChoices = @(Get-FocusChoices $tag)
            $focusChoice = $focusChoices | Where-Object {
                $_.id -eq $focusValue -or $_.name -eq $focusValue -or $_.display -eq $focusValue -or $_.name -like "*$focusValue*"
            } | Select-Object -First 1
            if ($focusChoice) {
                $focusCmd = "eval_effect $tag = { complete_national_focus = $($focusChoice.id) }"
                [void]$orders.Add([pscustomobject]@{
                    id = 'agent_focus'
                    command = $focusCmd
                    reason = "愿景国策：$($focusChoice.name)"
                })
                $seen['agent_focus'] = $true
                $focusNote = "本周国策：$($focusChoice.name)"
            } else {
                $focusNote = "愿景里的国策「$focusValue」不在本国焦点树，未生成。"
            }
        }
        foreach ($item in @($data.actions)) {
            if ($orders.Count -ge 6) { break }
            $id = [string]$item.id
            if (-not $script:actionDefs.Contains($id)) { continue }
            $def = $script:actionDefs[$id]
            if (-not $def.AiSuggest -or $def.Risk -in @('high', 'extreme')) { continue }
            if ($seen.ContainsKey($id)) { continue }
            if ($id -like 'invest_*' -and $recent -contains $id) { continue }
            $target = ''
            if ($def.NeedsTarget) {
                $target = ([string]$item.target).Trim().ToUpperInvariant()
                if (-not $target) { continue }
                if ($target -ne $script:player -and -not $script:states.ContainsKey($target)) { continue }
            }
            $amount = ''
            if ($def.NeedsAmount) {
                $amount = if ($null -ne $item.amount) { [string]$item.amount } else { [string]$def.DefaultAmount }
                $n = 0
                if (-not [int]::TryParse($amount, [ref]$n)) { continue }
            }
            $text = ''
            if ($def.NeedsText) {
                $text = [string]$item.text
                if (-not $text) { continue }
                if ($def.TextPattern -and $text -notmatch $def.TextPattern) { continue }
            }
            $cmd = Get-ActionCommand $id $tag $target $amount $text
            if (-not $cmd) { continue }
            if ($cmd -notmatch '^(eval_effect|effect|add_equipment|add_latest_equipment)\s') { continue }
            $seen[$id] = $true
            [void]$orders.Add([pscustomobject]@{
                id = $id
                command = $cmd
                reason = [string]$item.reason
            })
        }
        if ($orders.Count -eq 0) {
            Add-SystemBubble "$weekTitle：没有通过校验的动作，未生成订单文件。" $UiMuted
            $lblStatus.Text = "$weekTitle：无有效动作"
            return
        }
        $commands = @($orders | ForEach-Object { $_.command })
        $files = Write-AgentOrders $commands
        $autoDone = $false
        $autoText = '未自动执行；手动 run。'
        if ($script:cfg.input_auto -and (Test-DfyHoi4DebugMode)) {
            try {
                Invoke-DfyConsoleFile 'dfy_orders.txt'
                $autoDone = $true
                $autoText = '软件已自动输入 run dfy_orders.txt。'
            } catch {
                $autoText = "软件自动执行失败：$($_.Exception.Message)"
            }
        }
        if (-not $autoDone -and $script:cfg.hid_auto) {
            $hidPort = Find-DfyHidPort
            if ($hidPort) {
                try {
                    Invoke-DfyHidRun | Out-Null
                    $autoDone = $true
                    $autoText = "HID 已自动执行（$hidPort）。"
                } catch {
                    $autoText = "HID 未执行：$($_.Exception.Message)；手动 run。"
                }
            }
        }
        $newNotes = if ($data.notes) { [string]$data.notes } else { $notes }
        $newGoal = if ($data.goal) { [string]$data.goal } else { $goal }
        if ($newGoal.Length -gt 500) { $newGoal = $newGoal.Substring(0, 500) }
        Set-AgentRecord $tag $newNotes @($orders) $newGoal
        $script:agentAutoTag = $tag
        $script:agentAutoDate = [string]$script:states[$tag].dateText
        $script:agentAutoLast = Get-Date
        $report = if ($data.report) { [string]$data.report } else { '已生成订单。' }
        try { Set-Clipboard -Value 'run dfy_orders.txt' -ErrorAction Stop } catch { [Windows.Forms.Clipboard]::SetText('run dfy_orders.txt') }
        $fileText = if ($files.Count) { ($files -join '；') } else { '未能写入文件' }
        $nextStep = if ($autoDone) { '' } else { '回游戏按 ~，粘贴 run dfy_orders.txt 执行；不自动运行。' }
        $goalShort = if ($newGoal.Length -gt 120) { $newGoal.Substring(0, 120) + '...' } else { $newGoal }
        $briefText = (@($data.brief) | Where-Object { $_ } | Select-Object -First 3) -join "`r`n"
        Add-SystemBubble "$weekTitle：$report`r`n愿景：$goalShort`r`n$focusNote`r`n$templateNote`r`n本周三件事：`r`n$briefText`r`n订单 $($orders.Count) 条，已写入：$fileText`r`n$autoText $nextStep" $UiCyan
        try {
            $line = "$(Get-Date -Format 's')`tweek`ttokens=$($result.Tokens)`tactions=$($orders.Count)`t$($commands -join ' || ')"
            Add-Content -LiteralPath $script:AgentLog -Value $line -Encoding UTF8
        } catch {}
        $lblStatus.Text = "$weekTitle：已生成 $($orders.Count) 条订单"
    } catch {
        Add-SystemBubble ("$weekTitle 失败：" + $_.Exception.Message) $UiRed
        $lblStatus.Text = "$weekTitle 失败"
    }
}
