# Minimal system for a new machine: boot, network, user, SSH, shell and editor.
# Every my.* switch keeps its default (off). To add a desktop, import
# ../../profiles/workstation.nix; see modules/options.nix for all switches.
{ ... }:
{
  my = {
    # 模板占位:安装到目标机器时改成实际用户名。
    user.name = "nixos";
    # 目标机器没有本仓库的检出,避免生成指向不存在路径的软链。
    configPath = null;
  };

  # hardware-configuration.nix 由 nixos-generate-config 在本机生成,见 hosts/README.md。
}
