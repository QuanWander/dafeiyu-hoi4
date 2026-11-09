# HOI4 机制底稿（实现前必读）

这份文档不是 wiki 抄写，而是把本项目实际依赖的 HOI4 机制、官方文档位置、以及“能做/不能做”的边界固定下来。后续 agent、行动、UI 都以此为准。

## 1. 作用域与 effect

- 我们通过 `eval_effect TAG = { effect }` 执行国家 effect。
- effect 里 `THIS` 是当前作用域，`ROOT` 是 effect 根，`PREV` 是上一层。
- **不要假设 `ROOT` 永远是目标国**。v1.0 之前投资日志在随机州里用 `ROOT.GetTag`，结果把玩家国记成执行国；后来改成外层 `THIS.GetTag`。
- 国家 effect 与州 effect 不同：`add_building_construction` 只能在州作用域，必须先 `random_owned_controlled_state`。
- 命令只接受 `eval_effect/effect/add_equipment/add_latest_equipment` 前缀，渲染前必须校验。

官方：`documentation/effects_documentation.md`

## 2. 国策

- 焦点树：`common/national_focus/*.txt`，节点有 `focus`、`prerequisite`、`mutually_exclusive`、`x/y`、`available`。
- `complete_national_focus = <id>` 是**直接完成**，不检查前置、互斥、可用性。
- 因此：
  - 焦点 ID 必须来自 `Get-FocusChoices`；
  - 不能把“AI 编的焦点名”直接执行；
  - 要做“按分支走”，必须自己解析 prerequisite/x/y，不能只靠名字。
- 当前软件只读焦点树名称，不读已完成进度；没有“当前焦点/剩余天数”。

官方：`effects_documentation.md` → `complete_national_focus`；游戏：`common/national_focus/`

## 3. 部队编制与训练

### 能做

- `division_template = { ... }`：向国家添加一个编制模板。
- `add_units_to_division_template = { ... }`：给现有模板加营/支援连。
- `create_unit = { division = "..."; owner = TAG; ... }`：直接生成单位。
- `load_oob = "ENG_1936"`：加载预设 OOB（整队）。

模板语法（游戏 decision 实例）：

```text
division_template = {
    name = "DFY 海军陆战队"
    is_locked = no
    priority = 1
    regiments = {
        marines = { x = 0 y = 0 }
        marines = { x = 0 y = 1 }
        marines = { x = 1 y = 0 }
    }
    support = {
        engineer = { x = 0 y = 0 }
        artillery = { x = 0 y = 1 }
    }
}
```

### 不能做

- 没有“训练队列”effect。`set_division_force_allow_recruiting` 只是允许招募，不排训练。
- `create_unit` 是直接生成，不是训练；不要把它说成“训练”。
- 真正的训练/部署在 UI/引擎状态里，需要 UI 自动化或内存层。

官方：`division_template`、`add_units_to_division_template`、`create_unit`、`load_oob`；游戏实例：`common/decisions/AFG.txt`、`AUS.txt`、`BALTIC.txt`

## 4. 空海军

- 没有“设置空军任务/海军任务”的官方 effect。
- `set_air_oob` 只用于 history，在游戏开始加载 OOB，不是实时任务。
- 能做的只有：
  - `air_experience` / `navy_experience`；
  - 加装备/舰船/飞机（`add_equipment` 等）；
  - `create_navy_leader` 等。
- 任务设置只能走 UI 自动化/内存层；当前不承诺。

官方：`effects_documentation.md` → `set_air_oob`、`air_experience`、`navy_experience`

## 5. 经济/建造

- `add_building_construction` 是州作用域，受 `free_building_slots` 限制。
- `instant_build = yes` 只免建造时间，不免空槽条件。
- 日志必须放在“实际加到建筑”的州作用域内，否则会出现“没加成也记成功”的假日志（v0.9.26 踩过）。
- 不能排玩家建造队列；只能 instant 加建筑。

官方：`add_building_construction`；游戏：`common/buildings/`

## 6. 外交/阵营

- `add_to_faction = TAG` 是**当前国家把 TAG 加进自己的阵营**。
- “让 AI 加入玩家阵营”是 AI 执行 `add_to_faction = 玩家`。
- “让玩家加入 AI 阵营”是 AI 执行 `add_to_faction = 玩家`，由 AI 作为领袖。
- 方向错了会得到完全相反的结果；v0.9.11 修过。
- `set_autonomy`、`annex_country` 是目标国 effect，高风险，必须二次确认。

官方：`effects_documentation.md` → `add_to_faction`、`set_autonomy`、`annex_country`

## 7. 状态与遥测

mod 每周写：

```text
DFY|state|tag=...|civ=...|mil=...|dock=...|div=...|manpower_k=...|ships=...|planes=...|war=...|res=...|faction=...|pp=...|stab=...|ws=...
```

这是**周快照**，不是实时：

- 没有生产线队列；
- 没有建造队列；
- 没有当前焦点/进度；
- 没有部队位置/编制；
- 没有空海军任务。

所以 agent 的“精细化”必须区分：

- 能由 effect 做的：国策、instant 建筑、模板、生成单位、经验、人力、装备、燃料；
- 只能 UI/内存做的：训练队列、部署、空海军任务、生产线调度、部队移动。

## 8. 通用编制模板（待实测）

基于常见通杀思路，先做三个，不追求 meta 极限：

| id | 名称 |  regiments | support |
|---|---|---|---|
| inf20 | DFY 步兵师 | 7 infantry + 2 artillery | engineer, artillery |
| marine20 | DFY 海军陆战队 | 7 marines + 2 artillery | engineer, artillery |
| armor20 | DFY 装甲师 | 6 tank + 4 motorized | engineer, maintenance |

注意：

- 营/支援连 token 必须是游戏合法类型；不同 DLC/版本可能变；
- 模板 effect 加入后不会自动训练；
- 必须先做一次干净测试：加模板 → 打开编制界面确认；
- 如果没有合法 token，整个 order 可能报错，不能猜测。

## 9. 现有 50 条行动审计

静态检查：

- 50 条 action 的 effect/command 名称全部能在官方文档或 `dfy_*` 脚本中找到；
- 但“名称有效”不等于“语义正确”。

重点审计：

| 行动 | 结论 |
|---|---|
| `add_to_faction` 相关 | 方向已修，需继续测玩家/AI 双方 |
| `force_*` | 目标 effect 作用域正确，但高风险 |
| `gift_*` | `add_equipment` 是控制台玩家作用域，不是 AI 库存扣除 |
| `invest_*` | 受空槽限制，已修假日志 |
| `complete_focus` | 直接完成，不检查前置/互斥 |
| `player_access` | FRA→ENG 已实测 |
| `create_faction` | 已移除，DLC/模板限制 |

## 10. 测试协议

1. 用**独立测试存档**，不要拿主存档试模板/强制；
2. 启动必须 `-debug_mode`；
3. 测试文件只放一条 effect + `dfy_log_state`；
4. 看 `game.log` 的 `DFY|action/state`，不要只看控制台“Running”；
5. 模板/编制要打开编制界面人工确认；
6. 任何“没看到 state 变化”的效果，先怀疑作用域/空槽/前置，不要先怀疑 AI。

## 11. 下一阶段实现顺序

1. 模板目录：inf20/marine20/armor20，一次只加一个，干净测试；
2. 本周计划卡：愿景/国策/三件事固定到 UI；
3. 国策分支：x/y + prerequisite 分组；
4. 预算闸门：本地规划默认 0 token，模型规划需手动开；
5. 空海军任务：只做“一个动作”的 UI 自动化验证，不承诺全接管。

## 12. 参考文件

- `documentation/effects_documentation.md`
- `documentation/triggers_documentation.md`
- `documentation/console_commands_documentation.md`
- `common/national_focus/`
- `common/decisions/AFG.txt`、`AUS.txt`、`BALTIC.txt`
- `common/ai_templates/`
- 本仓库 `mod/dafeiyu_hoi4/common/scripted_effects/dfy_effects.txt`
