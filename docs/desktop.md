# 桌面：启动、登录与锁屏

`ryoko` 使用 Niri + DankMaterialShell，登录界面为 Dank Greeter（greetd）。Plymouth
未启用，启动时直接进入 greeter。

| 环节 | 实现 | 配置位置 |
| --- | --- | --- |
| 引导 | systemd-boot | `hosts/ryoko/default.nix` |
| 登录 | Dank Greeter（greetd + niri） | `modules/nixos/desktop/default.nix` |
| 顶部栏 | Noctalia Shell | `modules/home/desktop/niri/noctalia.nix` |
| 锁屏与空闲 | DMS 自带锁屏与 IdleService | `modules/home/desktop/niri/dms/binds.kdl`，空闲策略在 DMS 设置界面 |
| 输入法 | Fcitx5 + Rime（小鹤音形） | `modules/home/desktop/fcitx5/` |

## 登录

greeter 的 niri 配置由 `modules/nixos/desktop/default.nix` 提供通用部分（触摸板轻触
等），输出来自 `hosts/ryoko/default.nix` 的 `my.desktop.outputs`，桌面与 greeter
共用。启动 greetd 前会从 `/home/ryoko` 复制 DMS 的 `settings.json`、`session.json`
与配色，因此主题和壁纸与桌面一致。

修改登录管理器配置后，使用 `nixos-rebuild boot` 并重启：

```bash
nixos-rebuild build --flake .#ryoko
sudo nixos-rebuild boot --flake .#ryoko
reboot
```

## Noctalia 与 DMS

Noctalia 负责顶部栏、桌面小组件与壁纸配色；通知、锁屏、Spotlight 与 xhup 插件仍由
DMS 提供。`noctalia.nix` 关闭了 Noctalia 的通知守护进程、锁屏和剪贴板，`dms/default.nix`
的初始化脚本则确保 DMS 自带 bar 关闭，避免两套 bar 同时出现。Noctalia 每次换壁纸时，
`wallpaper_changed` 钩子会把新路径同步到 DMS 的 `lockScreenWallpaperPath`。

ZEKniri 使用 Waybar 作为状态栏，因此 Noctalia 自己的 bar 保持关闭。Waybar 的配色由
Noctalia 模板生成到 `~/.config/waybar/colors-noctalia.css`，切换壁纸时自动刷新。

## 锁屏

- 手动锁屏：**Super+L**，对应 `dms ipc call lock lock`。
- 锁屏密码由 `dankshell` PAM 会话验证。
- 锁屏背景跟随 Noctalia 当前壁纸。
- 系统中没有启动 swayidle/swaylock，锁屏与空闲只由 DMS 管理。

### 空闲策略（在 DMS 设置界面中手动设置）

这些值保存在 DMS 自己可写的 `settings.json` 中，仓库不管理：

| 设置项 | 值 | 作用 |
| --- | --- | --- |
| 锁屏超时 | 600 | 空闲 10 分钟锁屏 |
| 锁屏后关屏 | 120 | 锁屏后再空闲 2 分钟关屏 |
| 休眠超时 | 0 | 不因空闲自动挂起 |
| 挂起前锁屏 | 开 | 合盖和 `systemctl suspend` 都会先锁屏 |
| loginctl 集成 | 开 | `loginctl lock-session` 触发 DMS 锁屏 |

## 文件管理

Nautilus 是默认的目录打开程序。系统启用 GVfs、UDisks2、udiskie 与 Sushi：

- U 盘、移动硬盘接入后自动挂载并通知，在 Nautilus 侧栏弹出/卸载。
- Android 手机选择「文件传输」后，可通过 MTP 浏览文件。
- `Ctrl+L` 输入 `sftp://主机/路径` 或 `smb://主机/共享` 可访问远程文件。
- 选中文件按空格打开 Sushi 预览；File Roller 提供图形压缩包管理。

文件管理配置在 `modules/home/desktop/file-manager.nix`，系统后端在
`modules/nixos/desktop/default.nix`。

## Home Manager 文件冲突与备份

`modules/nixos/default.nix` 中配置了自动编号备份策略。应用程序可能把 Home Manager
管理的符号链接（例如 `~/.config/mimeapps.list`）替换为普通文件；下次激活遇到内容
不同时，会先将它移到同目录的 `.backup`，再恢复声明式配置。若 `.backup` 已存在，旧
备份会依次保留为 `.backup.~1~`、`.backup.~2~`，最新移走的文件始终放在 `.backup`。

默认应用关联应修改仓库里的 `xdg.mimeApps` 配置。通过应用界面修改的关联可能在下次
激活时恢复为声明值，届时可从上述备份找回。

## 回滚与诊断

- 进入系统后回滚：`sudo nixos-rebuild switch --rollback`。
- 启动日志：`journalctl -b`、`journalctl -b -1`、`systemd-analyze blame`。
- 文字控制台：**Ctrl+Alt+F2** 等切换到 TTY；greetd 在 tty1 上。
- 排查 greeter 问题时，可临时设置 `services.displayManager.dms-greeter.logs.save = true`。
