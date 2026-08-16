# feedback-plugin

面向 AI 助手（DeepSeek Harness / WorkBuddy 等）的**学情阶段反馈插件包**：让 AI 把辅导老师的自然语言需求，直接写成「学情阶段反馈」网站的共享反馈模板。

**不需要浏览器，不需要 Playwright，不需要 Node.js。** 老师只需要描述想要什么评语；AI 负责问清规则、写好话术、调用网站 API 创建模板。老师回到网站导入 Excel 即可直接使用，不满意继续让 AI 改。

## 1. 仓库里有什么

| 路径 | 作用 |
|---|---|
| `skills/learning-stage-feedback/SKILL.md` | 主技能：需求澄清协议 + 辅导老师话术规范 + SQL/模板规则 + API 写入流程 |
| `skills/learning-stage-feedback/resources/api-reference.md` | 模板 API 契约、完整 JSON 字段表、合法示例、错误处置 |
| `skills/learning-stage-feedback/resources/copywriting-guide.md` | 话术写作手册：亲切、具体、有活人感，避免 AI 味 |
| `skills/learning-stage-feedback/resources/sql-templates.md` | 已实测 SQL 模板库（出勤/出门测/课堂参与/四段式反馈） |
| `skills/learning-stage-feedback/resources/preview-manifest.md` | **可选扩展协议**：仅 DeepSeek Harness 且已启用 `ui-feedback-preview` 时使用；其他宿主忽略 |
| `skills/learning-stage-feedback/resources/site-manual.md` | 网站验证手册，指导老师验收模板效果 |
| `install.sh` / `verify.sh` | macOS、Linux、WSL、Git Bash 的安装与自检脚本 |
| `install.ps1` / `verify.ps1` | Windows PowerShell 的安装与自检脚本 |

安装脚本只做一件事：把 `skills/learning-stage-feedback` 目录复制到当前宿主的技能目录，不安装任何依赖：

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
AI：  若宿主是 DeepSeek Harness 且扩展已启用 → 输出 `feedback-preview` 清单 → 渲染成评语情况看板
        ↓
其他 agent：不输出该清单，仍可正常使用网站验证
        ↓
老师：打开网站 → 导入 Excel → 搜索模板名 → 直接使用
        ↓
老师：哪句不满意 → 告诉 AI → AI 修改同一条模板（PUT）
```

模板保存在网站服务器，全员共享；AI 写入后其他老师点「同步」即可看到。

## 3. 安装

### 方式一：把仓库链接直接发给 AI（推荐）

在 DeepSeek Harness 或 WorkBuddy 里发一句：

> 帮我安装这个插件：https://github.com/baizz1/feedback-plugin

AI 会自动下载仓库、运行安装脚本并完成自检。脚本会自动识别当前宿主，无需手动选择目录。装好后重启或新开会话即可使用。

### 方式二：Windows PowerShell

```powershell
./install.ps1
./verify.ps1
```

### 方式三：macOS / Linux / WSL / Git Bash

```bash
bash install.sh
bash verify.sh
```

## 4. 使用

新会话里直接说需求即可，技能会自动加载：

> 帮我做一个给家长的阶段反馈模板，主要看出勤和出门测，语气温和一点。

需要强制触发时，消息中写「使用 learning-stage-feedback 技能」+ 需求；DeepSeek Harness TUI 也可以用 `/skill:learning-stage-feedback 附加指令`。

AI 会依次：问清需求 → 给话术确认稿 → 通过 API 写入线上模板库 → 回读核对 → 告诉你如何验证。后续修改只需说「把出门测那段的 85 改成 80」「总结句再短一点」，AI 会只改对应部分并更新同一条模板。

## 4.1 宿主兼容性（重要）

- 本插件核心技能与所有支持 skills 的 agent 兼容（DeepSeek Harness、WorkBuddy 等）。
- `ui-feedback-preview` 是 **DeepSeek Harness 仓库里的客户端 UI 插件**，不属于本仓库；其他 agent 用户不会下载到任何 React/前端代码。
- 随本仓库安装的 `resources/preview-manifest.md` 只是一个可选文本协议，且 SKILL 已要求：非 DeepSeek Harness 或未启用该扩展时不得输出 `feedback-preview` 代码块。它不影响其他宿主的工作流。

## 5. 常见问题

**真的不需要浏览器吗？** 不需要。模板创建和修改通过 HTTPS API 完成；只有最后“看渲染效果”由老师在网站上人工确认。

**Excel 会传到哪？** 不会上传。API 只接收模板配置；Excel 仍在老师浏览器本地处理。

**模板存在哪？** 网站服务器 D1 数据库；**全员共享、无个人隔离**。新建、修改、删除会影响所有老师，因此 AI 执行删除前会二次确认，修改前会先读取线上最新版本。

**AI 会不会写坏 SQL？** 技能内置站点同款 SQL 校验规则，写入前要求 AI 逐条自检；服务端也会做语法/结构校验。SQL 最终渲染效果仍需老师在网站上用三类学生抽查。

**WorkBuddy 能用吗？** 能。技能是标准 `SKILL.md` 格式，安装脚本会自动装到 WorkBuddy 的技能目录。

**网站改版了怎么办？** 若 API 路径或 JSON 结构变化，更新 `resources/api-reference.md`；若话术偏好变化，更新 `copywriting-guide.md` 和 `SKILL.md`。

## 6. 目录结构

```text
feedback-plugin/
├── README.md                       # 使用说明
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
