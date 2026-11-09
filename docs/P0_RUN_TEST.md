# P0：验证 `run <文件>`

状态：**待一次人工实测**。不能模拟键盘，所以必须由玩家在游戏控制台执行一次。

## 文件

已放到两处，内容相同：

- `E:\SteamLibrary\steamapps\common\Hearts of Iron IV\dfy_p0_test.txt`
- `D:\360MoveData\Users\26370\Documents\Paradox Interactive\Hearts of Iron IV\dfy_p0_test.txt`

内容：

```text
eval_effect GER = { add_political_power = 1 }
eval_effect GER = { add_political_power = 1 }
eval_effect GER = { dfy_log_state = yes }
```

## 执行

1. 进入游戏，选任意存档；
2. 按 `~` 打开控制台；
3. 输入：
   ```text
   run dfy_p0_test.txt
   ```
4. 回车。

## 通过标准

- 德国政治点 +2；
- `game.log` 出现一条 `DFY|state|tag=GER|...`。

## 失败时

- 换到游戏根目录再试一次；
- 若两条 `eval_effect` 只执行一条，记录为“run 不支持多行”；
- 若提示找不到文件，记录实际搜索目录；
- P1 的“托管一周”仍能生成订单文件，但不能承诺一键执行。
