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

## 结论

- 游戏根目录的 `dfy_p0_test.txt` 能被 `run` 找到；
- 一次 `run` 可以执行多条 `eval_effect`；
- `run` 可用，P1 可以用 `run dfy_orders.txt`。
