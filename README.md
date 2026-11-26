# NixOS 配置仓库

`ryoko` 单机的 NixOS + Home Manager 配置：Niri + DankMaterialShell，登录界面为 Dank Greeter；日常应用全部声明在配置中，`nix profile` 只用于试用。

## 换电脑 / 重装

新机器（或重装）复用当前配置，只需克隆后生成该机的硬件配置：

```bash
git clone https://github.com/Shinonome-Ryoko14/NixOS-config.git ~/nixos-config
cd ~/nixos-config
sudo nixos-generate-config --root / --show-hardware-config > hosts/ryoko/hardware-configuration.nix
git add -N -f hosts/ryoko/hardware-configuration.nix
sudo nixos-rebuild switch --flake .#ryoko
```

前提：新机器的用户名与主机名都是 `ryoko`，且仓库位于 `~/nixos-config`。不同的话修改
`hosts/ryoko/default.nix` 里的 `my.user.name` 和 `my.configPath`。`.#nixos` 是
`.#ryoko` 的别名。

`hardware-configuration.nix` 含有本机磁盘 UUID，不能复用其他机器的文件；上面的
`nixos-generate-config` 必须在目标机器上执行，详见 [hosts/README.md](hosts/README.md)。

## 构建

```bash
nixos-rebuild build --flake .#ryoko
sudo nixos-rebuild switch --flake .#ryoko
```

改变图形登录配置时，构建通过后使用 `sudo nixos-rebuild boot --flake .#ryoko` 并重启。
配置结构、功能开关与常用操作见 [配置说明](docs/configuration.md)；登录、桌面与锁屏细节见
[桌面说明](docs/desktop.md)。

## 自定义安装镜像

`installer` 是独立的 x86_64 Linux 安装环境，使用 NixOS minimal ISO，开机启用 SSH，
并允许 `secrets/keys.nix` 中的维护者公钥登录 root。镜像包含 Git、Jujutsu（`jj`）、
Vim、NetworkManager 和 Nix flakes 支持，不导入日常主机的共享配置和功能模块。

```bash
nix build .#installer-iso --out-link result-installer
ls -lh result-installer/iso/*.iso
```

可以把 ISO 复制到 Ventoy，或写入 U 盘。下面的 `dd` 会覆盖整个目标设备，先用
`lsblk` 确认 U 盘，并将 `/dev/sdX` 替换为实际设备（不是分区）：

```bash
lsblk
sudo dd if=result-installer/iso/*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## 配置结构

- `flake.nix` / `flake.lock`：锁定输入、主机入口、安装镜像和项目模板。
- `lib/default.nix`：`mkHost`，接入共享模块、Home Manager 和 `hosts/ryoko`，并设置主机名。
- `modules/options.nix`：全部 `my.*` 开关的集中声明与依赖断言。
- `modules/nixos/`：系统层。`core.nix`（启动、网络、用户、防火墙、Nix、direnv）、`nix-cache.nix`、`overlays.nix`，以及 `desktop/`、`hardware/`、`virtualisation.nix`、`programs.nix`。
- `modules/home/`：Home Manager 层。`shell/`（Zsh、Neovim、CLI、`ryoko`）、`desktop/`（Niri、DMS/Noctalia、输入法、文件管理等）与 `apps.nix`。
- `hosts/ryoko/`：本机开关覆盖、硬件配置和 Home Manager 覆盖。
- `templates/project/`：通用 devShell 模板（`#project`）和 Java 8 Servlet/JSP 可执行 JAR 模板（`#java-webapp`）。
- `secrets/keys.nix`：安装镜像使用的 SSH 公钥；日常主机不再引用加密凭据。

## 常用操作

```bash
# 日常开关：查看、启用/禁用应用，添加/移除受管软件包
ryoko list
ryoko enable qq
ryoko add obsidian
ryoko apply

# 试用软件：nix shell 不留痕迹，nix profile 可保留一段时间
nix shell nixpkgs#obsidian
nix profile install nixpkgs#obsidian
# 决定长期使用后，用 ryoko add 写入受管清单并从 profile 移除
nix profile remove obsidian

# 版本管理
git status
git diff

# 更新输入、检查与格式化
ryoko update
nix flake check
nix fmt
```

不编辑自动生成的 `hardware-configuration.nix`。新增脚本使用 `/usr/bin/env` shebang。
先 build 再激活，不自动清理旧系统代际。
