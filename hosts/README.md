# Hosts Configuration

This directory contains NixOS configurations for different devices (hosts).

## Structure

Each host has its own directory containing:

- `default.nix` - Imports a profile from `../profiles`, overrides `my.*` switches (declared in `../modules/options.nix`, all off by default) and holds host-only settings
- `hardware-configuration.nix` - Hardware-specific configuration, generated on the machine and **not committed** (see below)
- `home.nix` - Optional Home Manager overrides for this host
- `optional files` - Additional host-specific configuration (hardware quirks, single-host services)

Shared modules, Home Manager and the host name are wired in by `mkHost` in `../lib/default.nix`.

## Current Hosts

- `laptop/` - Laptop configuration with mobile-specific settings
- `class/` - Minimal base-derived system with Btrfs partitions alongside Windows; see [installation guide](../docs/class-installation.md)
- `home/` - Home desktop with NVIDIA, printing and Syncthing
- `base/` - Minimal configuration for installing a new machine
- `vps/` - ARM64 Oracle Cloud server with SSH, selected CLI tools and whole-disk disko; see [installation guide](../docs/vps-installation.md)
- `installer/` - Standalone minimal live ISO with root SSH access using the maintainer key from `secrets/keys.nix`

## 硬件配置不入库

`hosts/<主机>/hardware-configuration.nix` 含有磁盘 UUID 等仅属于本机的信息,因此被
`.gitignore` 排除,由目标机器在部署时生成:

```bash
sudo nixos-generate-config --root / --show-hardware-config \
  > "hosts/$(hostname)/hardware-configuration.nix"
git add -N -f "hosts/$(hostname)/hardware-configuration.nix"
```

`git add -N -f` 只把文件登记为「intent-to-add」:Nix flake 只读取 Git 已跟踪的文件,
没有这一步时 `nixos-rebuild --flake .#<主机>` 会看不到它。该命令不会把内容写进提交;
`.githooks/pre-commit` 会在 `git add -A` 误暂存时自动撤销内容,只保留这个标记。
仓库克隆到新机器后,第一次构建前必须重新执行上面两条命令。

> 切换分支前先执行 `git reset -- hosts/*/hardware-configuration.nix`,否则 Git 会把
> 带 intent-to-add 标记的文件当成待删除的跟踪文件,连本地文件一起移除。内容不会真正
> 丢失,可用 `git show <提交>:hosts/<主机>/hardware-configuration.nix` 恢复。

## Adding a New Host

1. Create a new directory: `mkdir hosts/new-host`
2. Copy `base/default.nix`, set `my.user.name` (required, no default) and import a profile (e.g. `../../profiles/workstation.nix`)
3. Generate hardware configuration with the two commands above
4. Add `nixosConfigurations.new-host = mkHost "new-host";` to `flake.nix`
5. Add `home.nix` and `my.home.imports = [ ./home.nix ];` if the host needs Home Manager overrides; set `my.configPath = null;` when the machine has no checkout at `~/nixos-config`

Secrets are optional: `my.nix.cacheProfile` defaults to `public`, and no `.age`
file is required to build. Only when you actually need a secret do you add your
public key to `secrets/keys.nix` and create it with `ragenix -e`.

`mkHost "name"` defaults to x86_64 Linux. For another architecture use
`mkHost { name = "vps"; system = "aarch64-linux"; }`; this also passes the correct
architecture to Home Manager and package inputs. The VPS uses a hand-written
`hardware.nix` with QEMU guest support and disko-owned filesystems.

## Usage

Build configuration for a specific host:
```bash
nixos-rebuild build --flake .#hostname
```

`base` is a standalone minimal configuration for new machines, not a variant of another host. Generate its `hardware-configuration.nix` on the target machine as described above before installing.
See [安装入口、功能开关与应用](../docs/installation-profiles.md) for profiles, switches, applications and project devShells.

`installer` imports the upstream installation CD module directly and needs no generated hardware configuration or feature switches.
Build it with `nix build .#installer-iso --out-link result-installer`; see the [自定义安装镜像](../README.md#自定义安装镜像) instructions for writing and booting the ISO.
