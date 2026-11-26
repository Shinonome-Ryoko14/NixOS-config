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

日常开关交给 `ryoko`：

```bash
ryoko list              # 查看应用开关和受管软件包
ryoko list -i           # 用 fzf 交互切换
ryoko enable qq         # 启用应用开关
ryoko disable qq
ryoko add obsidian      # 加入受管软件包
ryoko remove obsidian
ryoko qq off            # enable/disable 的简写
```

应用名定义在 `modules/app-catalog.nix`，启用清单是
`hosts/ryoko/enabled-apps.nix`，额外软件包是
`hosts/ryoko/extra-packages.nix`。手工修改这两个文件同样有效；`ryoko` 只
维护清单，不会改写其他 Nix 配置。`enable/disable/add/remove` 默认先构建，再
询问是否切换；`--no-build` 只改文件，`--dry-run` 只显示差异。

新增一个可开关的应用：

1. 在 `modules/app-catalog.nix` 加名称和描述；
2. 在 `modules/home/apps.nix` 的包表中加入对应软件包；
3. 运行 `ryoko enable <名称>`。

`ryoko` 的日常命令：

| 命令 | 作用 |
| --- | --- |
| `ryoko apply [--build\|--boot\|--test]` | 构建，默认询问后 switch |
| `ryoko status` | 仓库、代际、磁盘与服务状态 |
| `ryoko update [输入]` | 更新 flake 输入并构建 |
| `ryoko gen [编号]` / `ryoko gen rollback` | 查看或切换代际 |
| `ryoko gc [--days N] [--yes]` | 清理旧代际，默认 dry-run |
| `ryoko ime status\|restart\|deploy\|add\|lookup\|sync` | Fcitx5/Rime 与 xhup 词库 |
| `ryoko wall [next\|random\|prev\|get\|list\|图片]` | 切换壁纸 |
| `ryoko timer 25m 休息` | 计时并在结束时通知 |
| `ryoko lock` / `suspend` / `reboot` / `shutdown` / `power` | 电源与锁屏 |
| `ryoko git status\|save\|sync` | 查看、提交、同步配置仓库 |
| `ryoko upload [-b 分支] [--pr]` | 新建分支、提交并推送到 GitHub |

不带参数的 `ryoko` 会打开 fzf 操作面板。`ryoko git save/upload` 用文件级
多选提交，始终排除 `hosts/*/hardware-configuration.nix`。

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
