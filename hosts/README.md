# Host Configuration

本目录只包含 `ryoko` 一台安装主机，以及构建安装镜像用的 `installer`。

## ryoko

- `default.nix` - 设置 `my.*` 开关，并放置本机系统配置
- `home.nix` - 本机的 Home Manager 覆盖，通过 `my.home.imports` 引入
- `hardware-configuration.nix` - 由目标机器生成，**不入库**

## 硬件配置不入库

`hosts/ryoko/hardware-configuration.nix` 含有磁盘 UUID 等仅属于本机的信息，因此被
`.gitignore` 排除，由目标机器在部署时生成：

```bash
sudo nixos-generate-config --root / --show-hardware-config \
  > hosts/ryoko/hardware-configuration.nix
git add -N -f hosts/ryoko/hardware-configuration.nix
```

`git add -N -f` 只把文件登记为「intent-to-add」：Nix flake 只读取 Git 已跟踪的文件，
没有这一步时 `nixos-rebuild --flake .#ryoko` 会看不到它。该命令不会把内容写进提交；
`.githooks/pre-commit` 会在 `git add -A` 误暂存时自动撤销内容，只保留这个标记。

> 切换分支前先执行 `git reset -- hosts/*/hardware-configuration.nix`，否则 Git 会把
> 带 intent-to-add 标记的文件当成待删除的跟踪文件，连本地文件一起移除。内容不会真正
> 丢失，可用 `git show <提交>:hosts/ryoko/hardware-configuration.nix` 恢复。

## installer

`installer/default.nix` 是独立的 live ISO 配置，不导入日常主机的共享模块，也不需要
生成的硬件配置。构建命令见仓库根目录的 [README](../README.md#自定义安装镜像)。
