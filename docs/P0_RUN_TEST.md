# P0：验证 `run <文件>`

状态：**已验证通过（2026-11-09 21:53）**。

## 实测证据

`game.log`：

```text
[21:53:19] DFY|state|tag=GER|...|pp=4.324|...
[21:53:23] DFY|state|tag=GER|...|pp=6.324|...
```

德国政治点 **4.324 → 6.324**，正好 +2；两条 `eval_effect` 都执行了，第三条 `dfy_log_state` 也写入了日志。

注意：政治点是加在 **GER（德国，AI 国）**，不是玩家意大利。看玩家界面不会看到变化。

## 玩家可见版（英国）

如果当前玩的是英国，用：

```text
run dfy_p0_test_ENG.txt
```

文件在两处：

- `E:\SteamLibrary\steamapps\common\Hearts of Iron IV\dfy_p0_test_ENG.txt`
- `D:\360MoveData\Users\26370\Documents\Paradox Interactive\Hearts of Iron IV\dfy_p0_test_ENG.txt`

内容：

```text
eval_effect ENG = { add_political_power = 1 }
eval_effect ENG = { add_political_power = 1 }
eval_effect ENG = { dfy_log_state = yes }
```

英国政治点应 +2，日志出现 `DFY|state|tag=ENG|...`。

## P1 effect 复测（v0.9.27）

v0.9.26 的 `ROOT.GetTag` 嵌套后取到玩家国；v0.9.27 改成外层 `THIS.GetTag`，且先确认有自由槽。

重启游戏后运行：

```text
run dfy_p1_fra_test.txt
```

文件内容：

```text
eval_effect FRA = { dfy_action_invest_mil = yes }
eval_effect FRA = { dfy_log_state = yes }
eval_effect ENG = { dfy_log_state = yes }
```

通过：

- `DFY|action|invest_mil|tag=FRA`；
- `DFY|state|tag=FRA|...|mil=9`（原 8）；
- 不应出现 `invest_mil|tag=ENG`。

如果 FRA 无自由军工槽：没有 action 日志，FRA 仍 8；这不是日志错误，是 effect 没执行。



## 结论

- 游戏根目录的 `dfy_p0_test.txt` 能被 `run` 找到；
- 一次 `run` 可以执行多条 `eval_effect`；
- `run` 可用，P1 可以用 `run dfy_orders.txt`。
