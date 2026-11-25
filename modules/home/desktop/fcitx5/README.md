# Fcitx5 与小鹤音形

本目录声明 `ryoko` 的中文输入法：Fcitx5 + Rime（rime-crane / 小鹤音形），以及查询和
快速加词的辅助工具。

```
fcitx5/
├── default.nix          # Fcitx5、主题和 profile
├── rime.nix             # Rime 引擎与用户词典链接
├── xhup.nix             # xhup 查询、快速加词和 DMS 插件
├── packages.nix         # rime-crane 派生，由 rime.nix 与 xhup.nix 共用
├── config/              # Rime 自定义配置
├── dictionaries/        # 本地计算机术语与拼音覆盖
├── patches/             # rime-crane 补丁
├── scripts/             # xhup 编码、查询与加词脚本
└── tests/               # xhup Python/Rime 回归测试
```

## 常用修改入口

### 输入法列表

`config/profile` 定义 Fcitx5 的输入法顺序，`config/classicui.conf` 定义候选框主题。
两者由 `default.nix` 强制覆盖为声明式版本。

### 候选框主题

mellow 主题来自固定提交的 `fcitx5-mellow-themes`，在 `default.nix` 中按颜色名生成
`mellow-<color>` 与 `mellow-<color>-dark` 两套。

### Rime 词库

- 基础 schema 与词库：固定提交的 `rime-crane` 与 nixpkgs `rime-data`。
- 用户词库：私有仓库 `git@github.com:lihaoze123/xhup-dicts.git`，克隆到
  `~/src/xhup-dicts`。
- 生成的计算术语表：`dictionaries/computer-terms.txt` 与
  `dictionaries/computer-pinyin-overrides.txt`。

`rime.nix` 在首次激活时尝试克隆用户词库；离线或尚无 SSH 密钥时只警告，稍后手动克隆
并重新部署 Rime 即可。

### 查询与加词

- `xhup-lookup`：命令行查码。
- `xhup-add-word`：交互式加词，同时更新私有用户词库。
- DMS 插件 `flypyXhup`：启动器内查询、加词和字根图。

细节见：

- [查询说明](docs/xhup-lookup.md)
- [快速加词](docs/add-user-word.md)
- [计算机术语词库](docs/computer-dictionary.md)

## 测试

直接运行脚本，避免默认 discovery 漏掉含连字符的文件名：

```bash
python3 modules/home/desktop/fcitx5/tests/test-xhup-lookup.py
python3 modules/home/desktop/fcitx5/tests/test-xhup-add-word.py
python3 modules/home/desktop/fcitx5/tests/test-xhup-rime-integration.py
```

前两个需要 Python 与 PyYAML；Rime 集成测试还需要真实 Fcitx/Rime 环境，步骤见
[docs/add-user-word.md](docs/add-user-word.md)。

应用配置后重启 Fcitx5：

```bash
systemctl --user restart fcitx5-daemon.service
journalctl --user -u fcitx5-daemon.service -b
```
