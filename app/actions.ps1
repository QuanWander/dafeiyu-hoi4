$script:actionDefs = [ordered]@{
    'join_faction' = @{
        Name = '加入你的阵营'
        Category = '外交'
        Desc = 'AI 国家加入你所在的阵营；需要你已经建立或加入一个阵营。'
        Command = 'effect {0} add_to_faction = {1}'
        NeedsPlayer = $true
        AiSuggest = $true
        Verify = 'join'
    }
    'guarantee' = @{
        Name = '保障你的独立'
        Category = '外交'
        Desc = 'AI 国家给你独立保障；被保障后，别人打你它会参战。'
        Command = 'effect {0} give_guarantee = {1}'
        NeedsPlayer = $true
        AiSuggest = $true
        Verify = 'guarantee'
    }
    'leave_faction' = @{
        Name = '退出当前阵营'
        Category = '外交 · 高风险'
        Desc = '让 AI 国家退出它现在的阵营。高风险：可能直接改变战争格局。'
        Command = 'effect {0} leave_faction = yes'
        Risk = 'high'
        AiSuggest = $false
        Verify = ''
    }
    'declare_war' = @{
        Name = '对目标宣战'
        Category = '外交 · 高风险'
        Desc = '让 AI 国家对目标国家宣战。高风险：会立刻进入战争状态。'
        Command = 'effect {0} declare_war_on = { target = {2} type = annex_everything }'
        NeedsTarget = $true
        TargetDefault = 'none'
        Risk = 'high'
        AiSuggest = $false
        Verify = 'war'
    }
    'white_peace' = @{
        Name = '与目标白和'
        Category = '外交 · 高风险'
        Desc = '让 AI 国家与目标国家白和。高风险：会直接结束战争。'
        Command = 'effect {0} white_peace = {2}'
        NeedsTarget = $true
        TargetDefault = 'none'
        Risk = 'high'
        AiSuggest = $false
        Verify = 'peace'
    }
    'force_faction' = @{
        Name = '强制目标加入 AI 阵营'
        Category = '强制 · 不平等'
        Desc = '强行把目标国家拉进 AI 所在阵营。高风险：会改变阵营格局。'
        Command = 'effect {2} add_to_faction = {0}'
        NeedsTarget = $true
        TargetDefault = 'none'
        Risk = 'high'
        AiSuggest = $false
        Verify = ''
    }
    'force_leave_faction' = @{
        Name = '强制目标退出阵营'
        Category = '强制 · 不平等'
        Desc = '强行让目标国家退出它现在的阵营。高风险：可能直接拆掉一个阵营。'
        Command = 'effect {2} leave_faction = yes'
        NeedsTarget = $true
        TargetDefault = 'none'
        Risk = 'high'
        AiSuggest = $false
        Verify = ''
    }
    'force_access' = @{
        Name = '强制目标给 AI 通行权'
        Category = '强制 · 不平等'
        Desc = '让目标国家把军事通行权交给 AI。高风险：部队可以直接穿过目标领土。'
        Command = 'effect {2} give_military_access = {0}'
        NeedsTarget = $true
        TargetDefault = 'none'
        Risk = 'high'
        AiSuggest = $false
        Verify = ''
    }
    'force_puppet' = @{
        Name = '把目标变成附庸'
        Category = '强制 · 极高风险'
        Desc = '把目标国家变成 AI 的傀儡国。极高风险：会永久改变存档和外交格局。'
        Command = 'effect {0} set_autonomy = { target = {2} autonomy_state = autonomy_puppet }'
        NeedsTarget = $true
        TargetDefault = 'none'
        Risk = 'extreme'
        AiSuggest = $false
        Verify = ''
    }
    'force_annex' = @{
        Name = '直接吞并目标'
        Category = '强制 · 极高风险'
        Desc = '让 AI 直接吞并目标国家。极高风险：目标会灭国，可能直接结束本局。'
        Command = 'effect {0} annex_country = { target = {2} transfer_troops = yes }'
        NeedsTarget = $true
        TargetDefault = 'none'
        Risk = 'extreme'
        AiSuggest = $false
        Verify = ''
    }
    'player_access' = @{
        Name = '给玩家军事通行权'
        Category = '对玩家 · 援助'
        Desc = '让 AI 把军事通行权交给玩家。玩家部队可以穿过 AI 领土。'
        Command = 'effect {0} give_military_access = {1}'
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'player_join_ai_faction' = @{
        Name = '邀请玩家加入 AI 阵营'
        Category = '对玩家 · 外交'
        Desc = '让玩家加入 AI 所在阵营。玩家已经有阵营时会失败。'
        Command = 'effect {1} add_to_faction = {0}'
        Risk = 'high'
        AiSuggest = $true
        Verify = ''
    }
    'player_leave_faction' = @{
        Name = '逼玩家退出阵营'
        Category = '对玩家 · 施压'
        Desc = '强制玩家退出当前阵营。高风险：会直接拆掉玩家的外交布局。'
        Command = 'effect {1} leave_faction = yes'
        Risk = 'high'
        AiSuggest = $false
        Verify = ''
    }
    'gift_equipment' = @{
        Name = '送玩家步兵装备'
        Category = '对玩家 · 援助'
        Desc = '给玩家补步兵装备，默认 1000。用 add_equipment 控制台命令，直接进玩家库存。'
        Command = 'add_equipment {3} infantry_equipment_1'
        NeedsAmount = $true
        DefaultAmount = 1000
        MinAmount = 100
        MaxAmount = 50000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'gift_support' = @{
        Name = '送玩家支援装备'
        Category = '对玩家 · 援助'
        Desc = '给玩家补支援装备，默认 500。需要先研究对应装备；没研究就选“送玩家最新装备”。'
        Command = 'add_equipment {3} support_equipment_1'
        NeedsAmount = $true
        DefaultAmount = 500
        MinAmount = 50
        MaxAmount = 20000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'gift_artillery' = @{
        Name = '送玩家火炮'
        Category = '对玩家 · 援助'
        Desc = '给玩家补火炮，默认 500。需要先研究对应装备；没研究就选“送玩家最新装备”。'
        Command = 'add_equipment {3} artillery_equipment_1'
        NeedsAmount = $true
        DefaultAmount = 500
        MinAmount = 50
        MaxAmount = 20000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'gift_tank' = @{
        Name = '送玩家轻型坦克'
        Category = '对玩家 · 援助'
        Desc = '给玩家补轻型坦克底盘，默认 100。需要先研究对应装备；没研究就选“送玩家最新装备”。'
        Command = 'add_equipment {3} light_tank_chassis_1'
        NeedsAmount = $true
        DefaultAmount = 100
        MinAmount = 10
        MaxAmount = 5000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'gift_air' = @{
        Name = '送玩家战斗机'
        Category = '对玩家 · 援助'
        Desc = '给玩家补小型飞机机身，默认 100。需要先研究对应装备；没研究就选“送玩家最新装备”。'
        Command = 'add_equipment {3} small_plane_airframe_1'
        NeedsAmount = $true
        DefaultAmount = 100
        MinAmount = 10
        MaxAmount = 5000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'gift_convoy' = @{
        Name = '送玩家运输船'
        Category = '对玩家 · 援助'
        Desc = '给玩家补运输船，默认 50。需要先研究对应装备；没研究就选“送玩家最新装备”。'
        Command = 'add_equipment {3} convoy_1'
        NeedsAmount = $true
        DefaultAmount = 50
        MinAmount = 5
        MaxAmount = 1000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'gift_latest' = @{
        Name = '送玩家最新装备'
        Category = '对玩家 · 援助'
        Desc = '用 add_latest_equipment 给玩家最新已研究装备，默认 1000。具体装备报错时用这个。'
        Command = 'add_latest_equipment {3}'
        NeedsAmount = $true
        DefaultAmount = 1000
        MinAmount = 100
        MaxAmount = 50000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'transfer_state' = @{
        Name = '把州转给 AI'
        Category = '国家 · 高风险'
        Desc = '把指定州转给 AI 国家。需要州 ID，高风险，先备份。'
        Command = 'effect {0} transfer_state = {4}'
        NeedsText = $true
        TextLabel = '州 ID'
        TextPlaceholder = '例如 506'
        TextPattern = '^\d+$'
        Risk = 'high'
        AiSuggest = $false
        Verify = ''
    }
    'add_state_claim' = @{
        Name = '给 AI 添加州宣称'
        Category = '国家 · 高级'
        Desc = '给 AI 国家添加某州的宣称。需要州 ID，用于制造外交借口。'
        Command = 'effect {0} add_state_claim = {4}'
        NeedsText = $true
        TextLabel = '州 ID'
        TextPlaceholder = '例如 506'
        TextPattern = '^\d+$'
        Risk = 'medium'
        AiSuggest = $false
        Verify = ''
    }
    'add_state_core' = @{
        Name = '把州设为核心'
        Category = '国家 · 高风险'
        Desc = '把某州设成 AI 的核心州。需要州 ID，会影响人力/工业/停战。'
        Command = 'effect {0} add_state_core = {4}'
        NeedsText = $true
        TextLabel = '州 ID'
        TextPlaceholder = '例如 506'
        TextPattern = '^\d+$'
        Risk = 'high'
        AiSuggest = $false
        Verify = ''
    }
    'complete_focus' = @{
        Name = '完成国家焦点'
        Category = '国家 · 高级'
        Desc = '让 AI 直接完成一个国家焦点。需要焦点 ID（不是中文名）。'
        Command = 'effect {0} complete_national_focus = {4}'
        NeedsText = $true
        TextLabel = '焦点 ID'
        TextPlaceholder = '例如 ITA_italian_tankettes'
        TextPattern = '^[A-Za-z0-9_]+$'
        Risk = 'high'
        AiSuggest = $false
        Verify = ''
    }
    'add_idea' = @{
        Name = '给 AI 加国家精神'
        Category = '国家 · 高级'
        Desc = '给 AI 添加一个 idea/国家精神。需要 idea ID。'
        Command = 'effect {0} add_ideas = {4}'
        NeedsText = $true
        TextLabel = 'Idea ID'
        TextPlaceholder = '例如 CZE_army_readiness_3'
        TextPattern = '^[A-Za-z0-9_]+$'
        Risk = 'medium'
        AiSuggest = $false
        Verify = ''
    }
    'gift_fuel' = @{
        Name = '送玩家燃料'
        Category = '对玩家 · 援助'
        Desc = 'AI 给玩家加燃料，默认 10000。'
        Command = 'effect {1} add_fuel = {3}'
        NeedsAmount = $true
        DefaultAmount = 10000
        MinAmount = 100
        MaxAmount = 100000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'gift_pp' = @{
        Name = '给玩家政治点'
        Category = '对玩家 · 援助'
        Desc = 'AI 给玩家加政治点，默认 100。'
        Command = 'effect {1} add_political_power = {3}'
        NeedsAmount = $true
        DefaultAmount = 100
        MinAmount = 1
        MaxAmount = 1000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'gift_command' = @{
        Name = '给玩家指挥点'
        Category = '对玩家 · 援助'
        Desc = 'AI 给玩家加指挥点，默认 100。'
        Command = 'effect {1} add_command_power = {3}'
        NeedsAmount = $true
        DefaultAmount = 100
        MinAmount = 1
        MaxAmount = 1000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'gift_manpower' = @{
        Name = '给玩家人力'
        Category = '对玩家 · 援助'
        Desc = 'AI 给玩家加人力，默认 100000。'
        Command = 'effect {1} add_manpower = {3}'
        NeedsAmount = $true
        DefaultAmount = 100000
        MinAmount = 1000
        MaxAmount = 1000000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'squeeze_stability' = @{
        Name = '打压玩家稳定度'
        Category = '对玩家 · 施压'
        Desc = 'AI 让玩家掉 10% 稳定度。高风险：会直接影响玩家国内局势。'
        Command = 'effect {1} add_stability = -0.1'
        Risk = 'high'
        AiSuggest = $false
        Verify = ''
    }
    'squeeze_war_support' = @{
        Name = '打压玩家战争支持度'
        Category = '对玩家 · 施压'
        Desc = 'AI 让玩家掉 10% 战争支持度。高风险：会影响玩家动员和战争决策。'
        Command = 'effect {1} add_war_support = -0.1'
        Risk = 'high'
        AiSuggest = $false
        Verify = ''
    }
    'invest_civ' = @{
        Name = '扩建民用工厂'
        Category = '经济'
        Desc = '在 AI 国家随机一个有空位的州，瞬间加 1 座民用工厂。'
        Command = 'effect {0} dfy_action_invest_civ'
        AiSuggest = $true
        Verify = 'civ'
    }
    'invest_mil' = @{
        Name = '扩建军工'
        Category = '经济'
        Desc = '在 AI 国家随机一个有空位的州，瞬间加 1 座军工。'
        Command = 'effect {0} dfy_action_invest_mil'
        AiSuggest = $true
        Verify = 'mil'
    }
    'invest_dock' = @{
        Name = '扩建船坞'
        Category = '经济'
        Desc = '在 AI 国家随机一个有空位的沿海州，瞬间加 1 座船坞。'
        Command = 'effect {0} dfy_action_invest_dock'
        AiSuggest = $true
        Verify = 'dock'
    }
    'invest_infra' = @{
        Name = '扩建基础设施'
        Category = '经济'
        Desc = '在 AI 国家随机一个有空位的州，瞬间加 1 级基础设施。'
        Command = 'effect {0} dfy_action_invest_infra'
        AiSuggest = $false
        Verify = ''
    }
    'research' = @{
        Name = '增加科研槽'
        Category = '科研'
        Desc = '给 AI 国家加 1 个科研槽；比较强，建议只在对价足够时用。'
        Command = 'effect {0} add_research_slot = 1'
        AiSuggest = $true
        Verify = 'res'
    }
    'boost_pp' = @{
        Name = '增加政治点'
        Category = '政治'
        Desc = '给 AI 国家增加政治点，默认 100。'
        Command = 'effect {0} add_political_power = {3}'
        NeedsAmount = $true
        DefaultAmount = 100
        MinAmount = 1
        MaxAmount = 1000
        AiSuggest = $true
        Verify = 'pp'
    }
    'boost_stability' = @{
        Name = '提高稳定度'
        Category = '政治'
        Desc = '给 AI 国家加稳定度，默认 10%（0.10）。'
        Command = 'effect {0} add_stability = {3}'
        NeedsAmount = $true
        DefaultAmount = 0.1
        MinAmount = 0.01
        MaxAmount = 0.5
        Decimals = 2
        AiSuggest = $true
        Verify = 'stab'
    }
    'boost_war_support' = @{
        Name = '提高战争支持度'
        Category = '政治'
        Desc = '给 AI 国家加战争支持度，默认 10%（0.10）。'
        Command = 'effect {0} add_war_support = {3}'
        NeedsAmount = $true
        DefaultAmount = 0.1
        MinAmount = 0.01
        MaxAmount = 0.5
        Decimals = 2
        AiSuggest = $true
        Verify = 'ws'
    }
    'boost_command_power' = @{
        Name = '增加指挥点'
        Category = '军事'
        Desc = '给 AI 国家增加指挥点，默认 100。'
        Command = 'effect {0} add_command_power = {3}'
        NeedsAmount = $true
        DefaultAmount = 100
        MinAmount = 1
        MaxAmount = 1000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'boost_manpower' = @{
        Name = '补充人力'
        Category = '军事'
        Desc = '给 AI 国家加人力，默认 100000。'
        Command = 'effect {0} add_manpower = {3}'
        NeedsAmount = $true
        DefaultAmount = 100000
        MinAmount = 1000
        MaxAmount = 1000000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'boost_equipment' = @{
        Name = '补充步兵装备'
        Category = '军事'
        Desc = '给 AI 国家库存加步兵装备，默认 1000。'
        Command = 'effect {0} add_equipment_to_stockpile = { type = infantry_equipment amount = {3} }'
        NeedsAmount = $true
        DefaultAmount = 1000
        MinAmount = 100
        MaxAmount = 50000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'boost_fuel' = @{
        Name = '补充燃料'
        Category = '军事'
        Desc = '给 AI 国家加燃料，默认 10000。'
        Command = 'effect {0} add_fuel = {3}'
        NeedsAmount = $true
        DefaultAmount = 10000
        MinAmount = 100
        MaxAmount = 100000
        Risk = 'medium'
        AiSuggest = $true
        Verify = ''
    }
    'army_xp' = @{
        Name = '增加陆军经验'
        Category = '军事'
        Desc = '给 AI 国家加陆军经验，默认 50。'
        Command = 'effect {0} army_experience = {3}'
        NeedsAmount = $true
        DefaultAmount = 50
        MinAmount = 1
        MaxAmount = 500
        AiSuggest = $true
        Verify = ''
    }
    'navy_xp' = @{
        Name = '增加海军经验'
        Category = '军事'
        Desc = '给 AI 国家加海军经验，默认 50。'
        Command = 'effect {0} navy_experience = {3}'
        NeedsAmount = $true
        DefaultAmount = 50
        MinAmount = 1
        MaxAmount = 500
        AiSuggest = $true
        Verify = ''
    }
    'air_xp' = @{
        Name = '增加空军经验'
        Category = '军事'
        Desc = '给 AI 国家加空军经验，默认 50。'
        Command = 'effect {0} air_experience = {3}'
        NeedsAmount = $true
        DefaultAmount = 50
        MinAmount = 1
        MaxAmount = 500
        AiSuggest = $true
        Verify = ''
    }
}

