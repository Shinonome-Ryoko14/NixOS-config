# DankMaterialShell 配置

DMS 提供通知、锁屏、Spotlight、便签、截图和 xhup 插件；顶部栏与壁纸配色在启用
`my.desktop.noctalia` 时交给 Noctalia。

## 文件

| 路径 | 内容 |
| --- | --- |
| `default.nix` | DMS 服务、Quickshell、初始设置与 niri 片段 |
| `plugins.nix` | 计算器、翻译、番茄钟插件的固定版本与初始化 |
| `initialize-plugins.py` | 首次启用插件，之后保留 GUI 修改 |
| `binds.kdl` | DMS 快捷键，由 `default.nix` 安装为 `~/.config/niri/dms-bindings.kdl` |
| `niri.kdl` | 未启用 ZEKniri 时的 niri 主配置 |

`~/.config/DankMaterialShell/settings.json`、`session.json`、`plugin_settings.json`
和 `~/.config/niri/dms/*.kdl` 由 DMS 自己重写，因此激活时只在文件不存在时播种，
不会覆盖界面中的修改。

## 初始设置

`default.nix` 生成 `dms-settings.json` 与 `dms-session.json`，并通过
`dms-initialize` 在首次登录时安装：

- 24 小时制；
- 终端使用 `kitty`；
- 启动应用使用 `systemd-run --user`；
- 壁纸路径指向 `~/.background/wallpaper.jpg`；
- 启用 Noctalia 时关闭 DMS 自带 bar，避免两套 bar 同时出现。

## 插件

- `calculator`、`dankTranslate`、`dankPomodoroTimer` 固定在 `plugins.nix`。
- `dankTranslate` 使用 `translate-shell` 的 store 路径，避免依赖旧 PATH。
- 首次安装后会写入 `plugin_settings.json`，之后以界面设置为准。

## xhup 与输入法

DMS 的 `flypyXhup` 插件由 `../fcitx5/xhup.nix` 部署，提供小鹤音形字根图、反查和
快速加词；快捷键见 `binds.kdl`。

## 应用配置后

```bash
nixos-rebuild build --flake .#ryoko
sudo nixos-rebuild switch --flake .#ryoko
systemctl --user restart dms.service
```

DMS 的 `settings.json` 与 niri 片段是用户可写文件；需要恢复默认时删除对应文件后
重新登录或重新激活。
