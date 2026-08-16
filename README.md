# feedback-plugin

面向 DeepSeek Harness（DSH）的**学情阶段反馈插件包**：让 AI 助手把辅导老师的自然语言需求，直接写成「学情阶段反馈」网站的共享反馈模板。

**不需要浏览器插件，不需要 Playwright。** 老师只需要描述想要什么评语，AI 负责问清规则、写好话术、调用网站 API 创建模板；老师回到网站导入 Excel 即可直接使用，不满意继续让 AI 改。

## 它解决什么

辅导老师通常不会写 SQL、不会配 JSON，但家长反馈评语又需要灵活的个性化规则（出勤、出门测、课堂参与、任一天/平均水平……）。

本插件给 AI 装上三样东西：

| 组件 | 作用 |
|---|---|
| `skills/learning-stage-feedback/SKILL.md` | 主技能：自然语言需求澄清协议 + 辅导老师话术规范 + SQL/模板技术规则 + API 写入流程 |
| `resources/api-reference.md` | 模板 API 契约、完整 JSON 字段表、合法示例、错误处置 |
| `resources/copywriting-guide.md` | 话术写作手册：亲切、具体、有活人感，避免 AI 味 |
| `resources/sql-templates.md` | 已实测 SQL 模板库（出勤/出门测/课堂参与/四段式反馈） |
| `resources/site-manual.md` | 网站验证手册，指导老师验收模板效果 |
| `install.ps1` | Windows 一键安装：把技能复制到 DSH 技能目录 |
| `verify.ps1` | 自检：技能安装、HTTPS 能力、线上模板 API 可达 |

## 工作原理

```
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

## 使用前提

- 已安装 DeepSeek Harness（DSH），且会话支持执行 shell 命令（DSH 默认具备）。
- 不需要 Node.js、不需要 Chrome、不需要 @playwright/mcp。
- Windows + PowerShell 使用一键安装；其他系统手动复制技能目录即可。

## 安装

### 方式一：把仓库链接直接发给 AI（最省事）

在 DeepSeek Harness 里发一句：

> 帮我安装这个插件：https://github.com/baizz1/feedback-plugin （克隆后运行 install.ps1 和 verify.ps1，报告结果）

AI 会自动克隆仓库 → 运行 `install.ps1`（复制技能）→ 运行 `verify.ps1`（自检技能与线上 API）→ 报告结果。装好后重启 DSH GUI，新开会话即可使用。

### 方式二：Windows 一键脚本

```powershell
./install.ps1
./verify.ps1   # 所有项目应 PASS
```

### 方式三：手动安装

把 `skills/learning-stage-feedback/` 整个目录复制到以下任一位置：

- 用户级：`%USERPROFILE%\.dsh\skills\`（所有会话可见，推荐）
- 项目级：工作区的 `.agents\skills\` 或 `.dsh\skills\`

安装只做这一件事，不需要改任何 profile。

## 使用

新会话里直接说需求即可，技能会自动加载：

> 帮我做一个给家长的阶段反馈模板，主要看出勤和出门测，语气温和一点。

需要强制触发时：

- 消息中写「使用 learning-stage-feedback 技能」+ 需求
- TUI 斜杠命令：`/skill:learning-stage-feedback 附加指令`

AI 会依次：问清需求 → 给话术确认稿 → 通过 API 写入线上模板库 → 回读核对 → 告诉你如何验证。后续修改只需说「把出门测那段的 85 改成 80」「总结句再短一点」，AI 会只改对应部分并更新同一条模板。

## 常见问题

**真的不需要浏览器吗？** 不需要。模板创建和修改通过 HTTPS API 完成；只有最后“看渲染效果”由老师在网站上人工确认。如果 DSH 环境碰巧有浏览器工具，技能也可用于自动验证，但不是安装前提。

**Excel 会传到哪？** 不会上传。API 只接收模板配置；Excel 仍在老师浏览器本地处理。

**模板存在哪？** 网站服务器 D1 数据库；**全员共享、无个人隔离**。新建、修改、删除会影响所有老师，因此 AI 执行删除前会二次确认，修改前会先读取线上最新版本。

**AI 会不会写坏 SQL？** 技能内置站点同款 SQL 校验规则，写入前要求 AI 逐条自检；服务端也会做语法/结构校验。但 SQL 最终渲染效果仍需老师在网站上用三类学生抽查（技能会给出具体测试清单）。

**线上接口安全吗？** 当前网站模板 API 无鉴权且 CORS 全开，任何能联网的脚本都能调用。本插件在能力范围内要求 AI 严格遵守“先读后写、确认后写、写完回读”，但**建议站点后续为写入接口增加鉴权和回收站**，这需要修改网站源码，不在本插件范围内。

**网站改版了怎么办？** 若 API 路径或 JSON 结构变化，更新 `skills/learning-stage-feedback/resources/api-reference.md`；若话术偏好变化，更新 `copywriting-guide.md` 和 `SKILL.md`。无需重装工具。

**不用 DSH 的同事怎么用？** 把 `skills/learning-stage-feedback/` 里的说明文档交给任意带 shell 能力的 AI 使用；或直接把 `site-manual.md` 当人工操作手册。

## 目录结构

```
feedback-plugin/
├── README.md
├── install.ps1                     # 一键安装技能（不再安装 Playwright）
├── verify.ps1                      # 自检：技能 + HTTPS + 线上 API
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
