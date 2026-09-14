# Rime 设置备份 · 恢复说明

- **备份时间**：2026-09-14
- **来源机器**：NixOS + fcitx5-rime 5.1.21（librime 1.17.0），rime 用户目录 `~/.local/share/fcitx5/rime`
- **内容**：雾凇拼音 rime-ice 的**全部自定义补丁** + 短语表 + 装置信息 + 个人词频
- **不含**：上游词库/方案本体（`cn_dicts/`、`lua/`、`opencc/`、`en_dicts/`、`*.dict.yaml`、`default.yaml`、`symbols*.yaml`、`build/`），这些可重新下载（见第 2 步）

---

## TL;DR —— 四条命令

```bash
# 1. 先按第 2 步装好 fcitx5-rime 和雾凇拼音本体，然后退出 fcitx5
pkill -x fcitx5

# 2. 拷回定制（覆盖同名文件）
BK=/home/zerone/.config/nixos/home/system/fctix5/rime
DEST=$HOME/.local/share/fcitx5/rime
cp -v "$BK"/*.custom.yaml "$BK"/custom_phrase.txt "$BK"/custom_phrase_double.txt \
      "$BK"/installation.yaml "$BK"/user.yaml "$BK"/double_pinyin_flypy.schema.yaml "$DEST"/

# 3. （可选）找回个人词频：3533 条选词记录
cp -r "$BK/userdb/rime_ice.userdb" "$DEST"/

# 4. 启动并部署
fcitx5 -d --replace     # 或托盘图标 → Rime → 部署
```

---

## 1. 文件清单

| 文件 | 作用 | 丢了会怎样 |
|---|---|---|
| `rime_ice.custom.yaml` | 全拼主方案补丁：**模糊音**（zh/z、ch/c、sh/s、an/ang 双向）、**长句最多 3 条整句**、候选**常显拼音**、反查带声调、语法模型（万象 LTS）、**英文权重 0**、英文抢位过滤 `mode: all` | 所有全拼定制失效：简拼/纠错回到默认、英文又开始抢位 |
| `default.custom.yaml` | 方案列表：全拼 `rime_ice` + 小鹤双拼 | F4 里看不到小鹤 |
| `double_pinyin_flypy.custom.yaml` | 小鹤方案的同一套选项（语法模型、整句、拼音注释、英文权重 0） | 小鹤没有语法模型/英文降权 |
| `melt_eng.custom.yaml` | 英文/符号的派生拼写改用小鹤规则（`__include: melt_eng.schema.yaml:/algebra_double_pinyin_flypy`） | 小鹤下英文、符号输入异常 |
| `radical_pinyin.custom.yaml` | 部件拆字（`uU` 反查、`` ` `` 辅码）派生拼写改用小鹤规则 | 小鹤下拆字功能异常 |
| `custom_phrase.txt` | 自定义短语（全拼编码；当前是上游默认内容，可自行加词） | 置顶短语消失 |
| `custom_phrase_double.txt` | 自定义短语（小鹤编码，当前是空表） | 小鹤短语表报错/为空（**这个文件必须存在**） |
| `double_pinyin_flypy.schema.yaml` | 小鹤双拼方案本体（上游文件，本机 2026-06 版；一起存可保证版本一致） | 上游重新下载也有，但版本可能不同 |
| `installation.yaml` | 装置信息，`installation_id: 29c17150-f8a8-42d1-b971-e985c4f99ccd`（同步目录名由它决定） | 会被当成新装置，旧同步记录对不上 |
| `user.yaml` | 上次使用的方案、选项状态（rime 自动生成，可选） | 重新记一次状态，无实质损失 |
| `userdb/rime_ice.userdb/` | **你的个人词频**（LevelDB 目录，3533 条选词记录），可直接拷回 | 词频归零，要重新养成 |
| `sync/29c17150-…/rime_ice.userdb.txt` | 上面那份的**纯文本导出**（3533 行，可读、可用于官方同步） | 只是备份的另一种形态，不会失效 |

> fcitx5 本体配置（`fcitx5/profile`、`classicui.conf`、fluent 主题）已由 home-manager 管（`home/system/fctix5/default.nix`），不在本备份里。

---

## 2. 完整恢复步骤

### 第 0 步：装好 fcitx5 + rime + 雾凇拼音本体

**系统侧（NixOS）**：`home/system/fctix5/default.nix` 已有 `i18n.inputMethod`（fcitx5 + fcitx5-rime + configtool）。手动装的场景就是装 `fcitx5`、`fcitx5-rime`。

**rime 用户目录**：`~/.local/share/fcitx5/rime`

- **图形法**：下载压缩包 → **清空**该目录 → 解压进去 → 重新部署
  - <https://github.com/iDvel/rime-ice/releases/latest/download/full.zip>
  - 大陆镜像：<https://mirror.nju.edu.cn/github-release/iDvel/rime-ice/LatestRelease/full.zip>
- **命令行法（plum，自动打补丁 + 可装语法模型）**：

  ```bash
  cd ~ && git clone https://github.com/rime/plum.git plum && cd plum

  # 装本体（更新词库也只要重跑这一条）
  rime_dir="$HOME/.local/share/fcitx5/rime" bash rime-install iDvel/rime-ice

  # 小鹤双拼用户额外执行
  rime_dir="$HOME/.local/share/fcitx5/rime" bash rime-install iDvel/rime-ice:others/recipes/config:schema=double_pinyin_flypy

  # 万象语法模型（全拼 + 小鹤都要）
  rime_dir="$HOME/.local/share/fcitx5/rime" bash rime-install iDvel/rime-ice:others/recipes/grammar:schema=rime_ice
  rime_dir="$HOME/.local/share/fcitx5/rime" bash rime-install iDvel/rime-ice:others/recipes/grammar:schema=double_pinyin_flypy
  ```

  > 其他客户端若用户目录是 `~/.config/fcitx5/rime`，把 `rime_dir` 换成那个路径。

### 第 1 步：退出 fcitx5（保护个人词库不被占用）

```bash
pkill -x fcitx5
```

### 第 2 步：把定制拷回去

```bash
BK=/home/zerone/.config/nixos/home/system/fctix5/rime
DEST=$HOME/.local/share/fcitx5/rime

cp -v "$BK"/*.custom.yaml \
      "$BK"/custom_phrase.txt "$BK"/custom_phrase_double.txt \
      "$BK"/installation.yaml "$BK"/user.yaml \
      "$BK"/double_pinyin_flypy.schema.yaml \
      "$DEST"/
```

### 第 3 步（可选）：找回个人词频

```bash
# 方式 A：直接拷回词库目录（最直接）
cp -r "$BK/userdb/rime_ice.userdb" "$DEST"/

# 方式 B：走 rime 官方同步通道（跨设备迁移用的就是这招）
mkdir -p "$DEST/sync"
cp -r "$BK/sync/"* "$DEST/sync/"
# 然后启动 fcitx5，在 Rime 菜单里执行一次「用户资料同步」
# 前提：installation.yaml 里的 installation_id 与 sync/ 目录名一致（本备份已一致）
```

### 第 4 步：启动并部署

```bash
fcitx5 -d --replace
```

再执行一次部署：托盘/输入法菜单 → **Rime → 部署**（首次部署会把 `cn_dicts/` 编译成 `build/` 下的 `*.prism.bin` / `*.table.bin`，需要几秒到几十秒）。

### 第 5 步：验证（1 分钟）

| 操作 | 期望结果 |
|---|---|
| 全拼打 `xz` | 出「现在」（简拼恢复） |
| 全拼打 `wsm` | 出「为什么」（简拼恢复） |
| 全拼打 `zang` | 「长/张」排在「脏」前面（模糊音 + 权重 ×0.5 生效） |
| 全拼打 `rug` | 「如果」排在英文 `rug` 前面（英文权重 0 生效） |
| 候选右侧 | 显示拼音注释（`keep_comments`） |
| <kbd>F4</kbd> | 方案选单里有「小鹤双拼」 |
| 小鹤打 `xm` | 出「现/先/线」 |
| 小鹤打 `xmzd` | 出「现在」 |

---

## 3. 注意事项（踩过的坑）

1. **列表追加 `/+` 必须直接写在顶层 `patch:` 下**，不能写成 `- patch/+:` 包裹里的 `speller/algebra/+`：外层 merge 会把 `+` 剥掉，由「追加」变「覆盖」，上游 120 多条拼写规则被清空 → 简拼（`xz`）、自动纠错全部失效。（2026-09-14 就踩了这个坑）
2. **上游更新会覆盖文件**：`bash rime-install iDvel/rime-ice` 会覆盖 `custom_phrase.txt` 和所有上游文件 ⇒ 更新完把本目录的 `custom_phrase.txt` 再拷回去一次。`*.custom.yaml` 不会被覆盖（上游没有这些文件）。
3. **`custom_phrase_double.txt` 必须存在**（哪怕空表），双拼方案默认用它，缺失会报错/短语表为空。
4. **小鹤双拼不是「两键出词」**：每个音节固定 2 键（`xm` = xian），多字词按音节数（现在 = `xmzd`）。雾凇默认**关闭**首字母简拼（`double_pinyin_flypy.schema.yaml` 里 `abbrev` 那一行是注释掉的，注释说明会引发 3 字母歧义），所以双拼下打 `xz` 不出「现在」是正常的。
5. **想续用同步**：换机器时 `installation.yaml` 里的 `installation_id` 要保持一致，否则会被当成新装置。

---

## 4.（可选）交给 home-manager 托管

在 `home/system/fctix5/default.nix` 里，按现有 `xdg.configFile` 的写法加 `xdg.dataFile`（链接到 `~/.local/share/`）：

```nix
  xdg.dataFile = {
    "fcitx5/rime/rime_ice.custom.yaml".source = ./rime/rime_ice.custom.yaml;
    "fcitx5/rime/default.custom.yaml".source = ./rime/default.custom.yaml;
    "fcitx5/rime/double_pinyin_flypy.custom.yaml".source = ./rime/double_pinyin_flypy.custom.yaml;
    "fcitx5/rime/melt_eng.custom.yaml".source = ./rime/melt_eng.custom.yaml;
    "fcitx5/rime/radical_pinyin.custom.yaml".source = ./rime/radical_pinyin.custom.yaml;
    "fcitx5/rime/custom_phrase_double.txt".source = ./rime/custom_phrase_double.txt;
  };
```

注意：托管后这些文件是 `/nix/store` 里的只读链接（`*.custom.yaml` 没问题，rime 只读它们）；**不要**托管 `custom_phrase.txt`，否则 plum 更新时写不进去。改名/换路径后记得 `home-manager switch`。

---

## 附录：校验值（sha256）

恢复后可用 `sha256sum <文件>` 对比，确认与备份一致：

```
fd8a17d35666b96b53e2c019ba204b8a3e82c53e0f930bd1f7d5a64d5244f1f8  default.custom.yaml
760105cf44cf1d4c94541866f38f66994ef5e1eb3ed38850a0a1658d88eeb780  double_pinyin_flypy.custom.yaml
4fd2ffb0838548c599346cba4814338c2c73185cc162d0a89237c899d1c88f7e  melt_eng.custom.yaml
0362a8caa45f31fb465279057adce2575051c51d03639f09101550f89ab842d9  radical_pinyin.custom.yaml
7399f76d8207141f6d79cb1aac5930f41d0dbb00524526a4871b66254a5cf335  rime_ice.custom.yaml
dd344d785f7244c79fee1a1601cd7f928fb3cce8dad66d3e1dfa4962ba59b0d7  custom_phrase.txt
579fef0a3ce023f791fe75362d94441d794f28257948a099dd6d2aee1ce72692  custom_phrase_double.txt
d83313163e7a8b3ec57e4619072514df0b61873e7830f78eedcf28dfcbd6dce6  installation.yaml
cbf603cb3add2322008f6be410900b4ba634f2ac4e48c122c1463624874b87ed  double_pinyin_flypy.schema.yaml
3887e1d5c4358d2c515e60f70135f982cfa2468664b715b1560df9f922527251  sync/29c17150-f8a8-42d1-b971-e985c4f99ccd/rime_ice.userdb.txt
```
