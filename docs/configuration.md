# 配置说明

`ryoko` 单机的配置分为三层：`modules/options.nix` 集中声明开关，`modules/nixos` 与
`modules/home` 实现开关，`hosts/ryoko/default.nix` 选择当前启用的功能。所有 `my.*`
开关默认关闭。

## 当前启用的功能

| 开关 | 内容 |
| --- | --- |
| `desktop` | Niri、DankMaterialShell、Dank Greeter、Fcitx5/Rime、PipeWire、Nautilus、基础字体 |
| `desktop.utilities` | ghostty、neovide、pavucontrol、GNOME 磁盘、baobab、Filelight |
| `desktop.noctalia` | Noctalia Shell 顶栏 |
| `desktop.zekNiri` | ZEKniri 外观：Waybar、Noctalia 面板、niri 动画、模糊与主题 |
| `apps.*` | Edge、Chrome、微信、QQ、网易云音乐、VS Code、mpv |
| `fonts.extra` | 额外中文与排版字体 |
| `hardware.bluetooth` | 蓝牙及桌面小程序 |
| `programs.appimage` / `nixLd` / `steam` | AppImage、外部程序加载器、Steam |
| `virtualisation.docker` | rootless Docker |
| `cli.extra` | lazygit、zellij、tealdeer、fastfetch、btop、ouch、iperf、jjui、nh 等 |

`my.user.name`、`my.user.home`、`my.configPath` 和 `my.desktop.outputs` 在
`hosts/ryoko/default.nix` 中设置。`my.configPath` 指向本仓库的检出位置，Neovim 与
niri 配置链接到这里，改动无需重建即可生效。

## 新增应用或功能

1. 在 `modules/options.nix` 的 `my.apps` 下声明开关，或复用已有开关。
2. 在 `modules/home/apps.nix` 的包表中加入对应软件包。
3. 在 `hosts/ryoko/default.nix` 中启用开关。

试用软件不改配置：

```bash
nix shell nixpkgs#obsidian
nix profile install nixpkgs#obsidian
nix profile list
nix profile remove obsidian
```

确定长期使用后，把软件写进配置，切换到新系统，再从 profile 中移除，避免同一程序
有两份。普通自定义包通过官方 NUR 输入使用
`pkgs.nur.repos.lihaoze123.<包名>`，更新索引运行 `nix flake update nur`。

## 显示输出

`my.desktop.outputs` 同时生成桌面和 greeter 的 niri 输出配置。当前 `eDP-1` 为
`1920x1080@60.000`、缩放 1。修改后构建并切换；登录管理器相关变更使用
`nixos-rebuild boot` 后重启。

## 开发环境

系统不全局安装 GCC、Clang、Rust、JDK、Node、Bun、Python 开发环境和 IDE。Neovim
只为自身附带 tree-sitter、gcc、Node.js 和 clangd，不启用 Node/Python/Ruby provider；
项目需要的其他 LSP、编译器放入项目 devShell。

```bash
nix flake init -t /home/ryoko/nixos-config#project
nix develop .#rust   # 或 .#cpp / .#node / .#python / .#java
```

Java 8 + 内嵌 Tomcat 9 + javax Servlet/JSP 的最小项目：

```bash
mkdir my-webapp
cd my-webapp
nix flake init -t /home/ryoko/nixos-config#java-webapp
nix develop
mvn clean package
java -jar target/my-jsp-project.jar
```

访问 `http://localhost:8080/` 和 `/hello`。项目使用 jj 时，新文件写入后执行
`jj status` 让 flake 能读取它们；使用 Git 时执行 `git add -N`。
