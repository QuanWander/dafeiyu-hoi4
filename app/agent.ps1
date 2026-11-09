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

function Set-AgentRecord([string]$tag, [string]$notes, $actions) {
    $store = Get-AgentStore
    $store[(Get-AgentKey $tag)] = [pscustomobject]@{
        notes = $notes
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

function Get-AgentActionList {
    $rows = @()
    foreach ($id in $script:actionDefs.Keys) {
        $d = $script:actionDefs[$id]
        if (-not $d.AiSuggest) { continue }
        if ($d.Risk -in @('high', 'extreme')) { continue }
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

function Invoke-AgentWeek {
    if (-not $script:key) {
        Show-Settings
        if (-not $script:key) { return }
    }
    if ($script:advisorMode) {
        [Windows.Forms.MessageBox]::Show('同国参谋模式不托管；切回 AI 国家模式再试。', '托管一周')
        return
    }
    $tag = Get-SelectedTag
    if (-not $tag -or -not $script:states.ContainsKey($tag)) {
        [Windows.Forms.MessageBox]::Show('还没有 AI 国家状态。先启动游戏，等一周。', '没有状态')
        return
    }
    $allowed = Get-AgentActionList
    $notes = Get-AgentNotes $tag
    if (-not $notes) { $notes = '暂无长期笔记。' }
    $stateText = Get-AgentStateText $tag
    $prompt = @"
你是《钢铁雄心4》里正在玩 $tag 的玩家，不是外交官。玩家控制另一个国家，和你同局。
你要为下一周做 1-6 个决定，优先配合玩家、稳住自己的国家和战争目标。

当前状态（第 N 周开始时的快照，不是实时）：
$stateText
长期笔记：
$notes

只能从下面动作中选，不能编造动作：
$allowed

输出严格 JSON，不要 markdown：
{"report":"一句话说明本周计划","notes":"更新后的长期笔记（战略目标/承诺/当前重点）","actions":[{"id":"动作id","target":"目标国家代码，可为空","amount":1,"text":"文本参数，可为空","reason":"为什么"}]}

规则：
- actions 最多 6 个；
- 只能选上面列出的动作；
- 需要 target 的必须填真实国家代码；需要 amount 的填整数；需要 text 的按动作要求填；
- 不要选高风险/强制动作；
- 不要重复同一个动作刷次数；
- 你不自动执行；玩家会运行订单文件。
"@
    $messages = @(
        @{ role = 'system'; content = '你只输出严格 JSON，不解释。' },
        @{ role = 'user'; content = $prompt }
    )
    $lblStatus.Text = '托管一周：正在规划...'
    [Windows.Forms.Application]::DoEvents()
    try {
        $result = Invoke-ChatApi $messages 900
        $script:tokens += $result.Tokens
        $match = [regex]::Match([string]$result.Reply, '(?s)\{.*\}')
        if (-not $match.Success) { throw '规划结果不是 JSON。' }
        $data = $match.Value | ConvertFrom-Json
        $orders = New-Object System.Collections.ArrayList
        $seen = @{}
        foreach ($item in @($data.actions)) {
            if ($orders.Count -ge 6) { break }
            $id = [string]$item.id
            if (-not $script:actionDefs.Contains($id)) { continue }
            $def = $script:actionDefs[$id]
            if (-not $def.AiSuggest -or $def.Risk -in @('high', 'extreme')) { continue }
            if ($seen.ContainsKey($id)) { continue }
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
            Add-SystemBubble '托管一周：没有通过校验的动作，未生成订单文件。' $UiMuted
            $lblStatus.Text = '托管一周：无有效动作'
            return
        }
        $commands = @($orders | ForEach-Object { $_.command })
        $files = Write-AgentOrders $commands
        $newNotes = if ($data.notes) { [string]$data.notes } else { $notes }
        Set-AgentRecord $tag $newNotes @($orders)
        $report = if ($data.report) { [string]$data.report } else { '已生成订单。' }
        try { Set-Clipboard -Value 'run dfy_orders.txt' -ErrorAction Stop } catch { [Windows.Forms.Clipboard]::SetText('run dfy_orders.txt') }
        $fileText = if ($files.Count) { ($files -join '；') } else { '未能写入文件' }
        Add-SystemBubble "托管一周：$report`r`n订单 $($orders.Count) 条，已写入：$fileText`r`n回游戏按 ~，粘贴 run dfy_orders.txt 执行；不自动运行。" $UiCyan
        try {
            $line = "$(Get-Date -Format 's')`tweek`ttokens=$($result.Tokens)`tactions=$($orders.Count)`t$($commands -join ' || ')"
            Add-Content -LiteralPath $script:AgentLog -Value $line -Encoding UTF8
        } catch {}
        $lblStatus.Text = "托管一周：已生成 $($orders.Count) 条订单"
    } catch {
        Add-SystemBubble ("托管一周失败：" + $_.Exception.Message) $UiRed
        $lblStatus.Text = '托管一周失败'
    }
}
