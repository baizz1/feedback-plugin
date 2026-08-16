# feedback-plugin

面向 AI 助手（DeepSeek Harness / WorkBuddy 等）的**学情阶段反馈插件包**：让 AI 把辅导老师的自然语言需求，直接写成「学情阶段反馈」网站的共享反馈模板。

**不需要浏览器，不需要 Playwright，不需要 Node.js。** 老师只需要描述想要什么评语；AI 负责问清规则、写好话术、调用网站 API 创建模板。老师回到网站导入 Excel 即可直接使用，不满意继续让 AI 改。

---

## 1. 仓库里有什么

| 路径 | 作用 |
|---|---|
| `skills/learning-stage-feedback/SKILL.md` | 主技能：需求澄清协议 + 辅导老师话术规范 + SQL/模板规则 + API 写入流程 |
| `skills/learning-stage-feedback/resources/api-reference.md` | 模板 API 契约、完整 JSON 字段表、合法示例、错误处置 |
| `skills/learning-stage-feedback/resources/copywriting-guide.md` | 话术写作手册：亲切、具体、有活人感，避免 AI 味 |
| `skills/learning-stage-feedback/resources/sql-templates.md` | 已实测 SQL 模板库（出勤/出门测/课堂参与/四段式反馈） |
| `skills/learning-stage-feedback/resources/site-manual.md` | 网站验证手册，指导老师验收模板效果 |
| `install.sh` / `verify.sh` | macOS、Linux、WSL、Git Bash 的安装与自检脚本 |
| `install.ps1` / `verify.ps1` | Windows PowerShell 的安装与自检脚本 |

安装脚本只做一件事：**把 `skills/learning-stage-feedback` 目录复制到当前宿主的技能目录**，不安装任何依赖：

- DeepSeek Harness：`~/.dsh/skills/learning-stage-feedback/`
- WorkBuddy：`~/.workbuddy/skills/learning-stage-feedback/`

## 2. 工作原理

```text
老师：帮我做一个给家长的阶段反馈模板，主要看出勤和出门测
        ↓
AI：  追问对象、语气、规则（平均还是任一天、阈值、缺测怎么办）
        ↓
AI：  给出中文确认稿（每段话 + 什么时候出现），老师确认
        ↓
AI：  生成模板 JSON → POST/PUT 到网站模板 API → GET 回读核对
        ↓
老师：打开网站 → 导入 Excel → 搜索模板名 → 直接使用
        ↓
老师：哪句不满意 → 告诉 AI → AI 修改同一条模板（PUT）
```

模板保存在网站服务器，全员共享；AI 写入后其他老师点「同步」即可看到。

---

## 3. 安装方式

### 方式一：把仓库链接直接发给 AI（推荐）

在 DeepSeek Harness 或 WorkBuddy 里发一句：

> 帮我安装这个插件：https://github.com/baizz1/feedback-plugin
> 安装完成后告诉我下一步怎么用。

AI 会阅读本 README 的「给 AI 的安装协议」并自动完成下载、安装、验证和汇报，用户不需要手动上传任何文件。装好后重启或新开会话即可使用。

### 方式二：DeepSeek Harness + Windows PowerShell

```powershell
./install.ps1
./verify.ps1   # 所有项目应 PASS
```

### 方式三：DeepSeek Harness + macOS / Linux / WSL / Git Bash

```bash
bash install.sh
bash verify.sh   # 所有项目应 PASS
```

> 脚本支持 `DSH_HOME` 环境变量。默认安装到 `~/.dsh/skills/learning-stage-feedback`。

### 方式四：WorkBuddy（全自动，无需上传 zip）

WorkBuddy 会扫描用户技能目录 `~/.workbuddy/skills/`，所以把技能文件夹复制进去即可：

macOS / Linux / WSL / Git Bash：

```bash
bash install.sh --workbuddy
bash verify.sh --workbuddy   # 所有项目应 PASS
```

Windows PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target WorkBuddy
powershell -ExecutionPolicy Bypass -File .\verify.ps1 -Target WorkBuddy
```

更省事：直接把仓库链接发给 WorkBuddy，让它按下面的协议自动安装，用户全程不用手动上传文件。

### 方式五：手动安装（任意支持 SKILL.md 的宿主）

把 `skills/learning-stage-feedback/` 整个目录复制到宿主的技能目录。DeepSeek Harness 的用户级目录是 `~/.dsh/skills/`；其他宿主按各自文档放置。

---

## 4. 给 AI 的安装协议（AI 必读）

> 本节写给执行安装任务的 AI。用户把本仓库链接发给你时，按本节执行，不要凭猜测。

### 4.1 任务目标

把本仓库中的技能 `skills/learning-stage-feedback` 安装到用户当前使用的 AI 宿主，并验证可用。**唯一需要安装的东西就是这个目录。不要安装 Playwright、浏览器、MCP、Node 包或其他依赖。**

### 4.2 第 0 步：确认宿主

先判断用户用的是哪个宿主：

- 用户说 DeepSeek Harness / DSH，或系统存在 `~/.dsh`、`%USERPROFILE%\.dsh` 目录 → 按 **4.4** 安装；
- 用户说 WorkBuddy，或系统存在 `~/.workbuddy`、`%USERPROFILE%\.workbuddy` 目录 → 按 **4.5** 直接安装；
- 无法判断时，只问一句：「您用的是 DeepSeek Harness 还是 WorkBuddy？」不要猜。

### 4.3 第 1 步：获取仓库

优先用 git：

```bash
git clone --depth 1 https://github.com/baizz1/feedback-plugin.git /tmp/feedback-plugin
```

没有 git 时下载 zip 并解压：

```bash
curl -L -o /tmp/feedback-plugin.zip https://github.com/baizz1/feedback-plugin/archive/refs/heads/master.zip
unzip -q /tmp/feedback-plugin.zip -d /tmp
# 解压后目录名通常为 feedback-plugin-master
```

### 4.4 第 2 步：DeepSeek Harness 安装

**macOS / Linux / WSL / Git Bash：**

```bash
cd /tmp/feedback-plugin   # 如果下载 zip 解压，则进入 feedback-plugin-master
bash install.sh --dsh
bash verify.sh --dsh
```

**Windows PowerShell：**

```powershell
cd <仓库目录>
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target DSH
powershell -ExecutionPolicy Bypass -File .\verify.ps1 -Target DSH
```

脚本成功标准：

- `install.sh` / `install.ps1` 输出 `all skill files present`；
- `verify.sh` / `verify.ps1` 输出 `All checks passed` 或 `All checks passed:`；
- 自检会只读请求一次 `https://follow-class-reminder.pages.dev/api/learning-feedback/templates`，确认网络和接口正常。

如果脚本无法执行（例如权限不足），手动等效安装：

- macOS / Linux：把 `skills/learning-stage-feedback` 复制到 `~/.dsh/skills/`；
- Windows：把同一目录复制到 `%USERPROFILE%\.dsh\skills\`。

### 4.5 第 2 步：WorkBuddy 直接安装（无需 zip，无需用户手动上传）

WorkBuddy 的用户技能目录是 `~/.workbuddy/skills/`。直接把技能目录复制进去，WorkBuddy 重启或新开会话后即可扫描到。

**macOS / Linux / WSL / Git Bash：**

```bash
cd /tmp/feedback-plugin   # 如果下载 zip 解压，则进入 feedback-plugin-master
bash install.sh --workbuddy
bash verify.sh --workbuddy
```

**Windows PowerShell：**

```powershell
cd <仓库目录>
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target WorkBuddy
powershell -ExecutionPolicy Bypass -File .\verify.ps1 -Target WorkBuddy
```

**脚本不可用时的手动等效安装：**

- macOS / Linux：`mkdir -p ~/.workbuddy/skills && cp -R skills/learning-stage-feedback ~/.workbuddy/skills/`
- Windows：把 `skills\learning-stage-feedback` 复制到 `%USERPROFILE%\.workbuddy\skills\`

安装成功后告诉用户：

> 插件已经装好了 ✅
> 请重启一下 WorkBuddy（或新开一个会话），然后直接跟我说：「帮我做一个家长反馈模板」，我就能开始。

如果 WorkBuddy 数据目录不在默认位置，shell 脚本可用 `WORKBUDDY_HOME` 环境变量指定后再安装。

### 4.6 第 3 步：通用验证

无论哪个宿主，安装完成后执行一次只读请求：

```bash
curl -fsS https://follow-class-reminder.pages.dev/api/learning-feedback/templates
```

返回 JSON 中包含 `"ok":true` 和 `"templates":[...]` 即接口正常。

### 4.7 第 4 步：向用户汇报

安装成功后，用简短的中文向用户汇报，并给出可立即复制使用的测试消息，例如：

> 插件已安装并验证通过 ✅
> 新开会话后可以直接说：
> 「帮我做一个给家长的阶段反馈模板，主要看出勤和出门测，语气温和一点。」
> 我会先跟您确认规则和话术，确认后直接写入网站模板库。

### 4.8 禁止事项

- 禁止安装 Playwright、浏览器、MCP、npm 包——本插件不需要。
- 不要要求用户手动上传 zip；直接复制到宿主技能目录。
- 禁止在非 Windows 系统上运行 `.ps1`；Windows 上优先 `.ps1`。
- 不要修改 `skills/learning-stage-feedback` 里的任何文件后再安装；用户没有明确要求就不要改。
- 安装阶段不要创建、修改或删除线上任何模板数据。

---

## 5. 使用

新会话里直接说需求即可，技能会自动加载：

> 帮我做一个给家长的阶段反馈模板，主要看出勤和出门测，语气温和一点。

需要强制触发时，消息中写「使用 learning-stage-feedback 技能」+ 需求；DeepSeek Harness TUI 也可以用 `/skill:learning-stage-feedback 附加指令`。

AI 会依次：问清需求 → 给话术确认稿 → 通过 API 写入线上模板库 → 回读核对 → 告诉你如何验证。后续修改只需说「把出门测那段的 85 改成 80」「总结句再短一点」，AI 会只改对应部分并更新同一条模板。

---

## 6. 常见问题

**真的不需要浏览器吗？** 不需要。模板创建和修改通过 HTTPS API 完成；只有最后“看渲染效果”由老师在网站上人工确认。如果宿主碰巧有浏览器工具，也可以用于自动验证，但不是安装前提。

**Excel 会传到哪？** 不会上传。API 只接收模板配置；Excel 仍在老师浏览器本地处理。

**模板存在哪？** 网站服务器 D1 数据库；**全员共享、无个人隔离**。新建、修改、删除会影响所有老师，因此 AI 执行删除前会二次确认，修改前会先读取线上最新版本。

**AI 会不会写坏 SQL？** 技能内置站点同款 SQL 校验规则，写入前要求 AI 逐条自检；服务端也会做语法/结构校验。但 SQL 最终渲染效果仍需老师在网站上用三类学生抽查（技能会给出具体测试清单）。

**Linux / macOS 能用吗？** 能。使用 `install.sh` 和 `verify.sh`；Windows 使用 `.ps1`。两者安装结果完全一样。

**WorkBuddy 能直接用吗？** 能。技能本身是标准 `SKILL.md` 格式，WorkBuddy 会扫描 `~/.workbuddy/skills/`。把仓库链接发给 WorkBuddy，AI 会直接复制安装，不需要用户手动上传 zip。

**网站改版了怎么办？** 若 API 路径或 JSON 结构变化，更新 `skills/learning-stage-feedback/resources/api-reference.md`；若话术偏好变化，更新 `copywriting-guide.md` 和 `SKILL.md`。无需重装工具。

**不用 DSH / WorkBuddy 的同事怎么用？** 把 `skills/learning-stage-feedback/` 目录交给任意支持 SKILL.md 的 AI 宿主；或直接把 `site-manual.md` 当人工操作手册。

## 7. 目录结构

```text
feedback-plugin/
├── README.md                       # 人类指南 + 给 AI 的安装协议
├── install.sh / verify.sh          # macOS / Linux / WSL / Git Bash
├── install.ps1 / verify.ps1        # Windows PowerShell
└── skills/learning-stage-feedback/
    ├── SKILL.md                    # 主技能（API-first 流程与话术规范）
    └── resources/
        ├── api-reference.md        # API 契约与模板 JSON 规范
        ├── copywriting-guide.md    # 辅导老师话术写作手册
        ├── sql-templates.md        # SQL 模板库
        └── site-manual.md          # 网站验证手册
```

## License

MIT
