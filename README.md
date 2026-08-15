# feedback-plugin

面向 DeepSeek Harness（DSH）的**学情阶段反馈插件包**：让 AI 助手在「学情阶段反馈」网站（follow-class-reminder.pages.dev）上，端到端辅助老师制作家长反馈评语模板。

## 它解决什么

一份技能（skill）只有知识没有手；浏览器工具只有手没有脑。本包把两者打成一个可安装的整体：

| 组件 | 作用 |
|---|---|
| `skills/learning-stage-feedback/` | 知识 + 五阶段评语制作流程 + 浏览器工具编排 + 现场决策清单 + 降级路径 |
| `install.ps1` | Windows 一键安装：@playwright/mcp + 浏览器 + DSH profile 配置 + 技能（幂等） |
| `verify.ps1` | 六项自检：node / mcp / 浏览器 / 配置 / 技能 / 进程 |
| `profile-patch-snippet.yml` | 手动合并 profile 配置时的模板片段 |

## 使用前提

- 已安装 DeepSeek Harness（DSH）
- Node.js 18+（install.ps1 会检查）
- Windows + PowerShell（install.ps1 面向 Windows；其它系统按手动安装操作）

## 安装

### 方式一：把仓库链接直接发给 AI（最省事）

在 DeepSeek Harness（或任意带 shell 能力的 AI 会话）里发一句：

> 帮我安装这个插件：https://github.com/baizz1/feedback-plugin （克隆后运行 install.ps1 和 verify.ps1，报告结果）

AI 会自动：克隆仓库 → 运行 install.ps1（装 @playwright/mcp + 配 profile + 装技能）→ 运行 verify.ps1 六项自检 → 报告结果。装好后重启 DSH GUI，新开会话即可使用。

### 方式二：Windows 一键脚本

```powershell
./install.ps1
./verify.ps1   # 六项应全部 PASS
```

重启 DSH GUI，新开会话发送测试消息：

> 检查浏览器工具是否可用；打开 https://follow-class-reminder.pages.dev/learning-stage-feedback 并报告页面标题。

### 方式三：手动安装

- 技能：把 `skills/learning-stage-feedback/` 复制到 `%USERPROFILE%\.dsh\skills\`（用户级，所有会话可见）或工作区的 `.agents\skills\` / `.dsh\skills\`（项目级）。
- 浏览器工具：全局安装 `@playwright/mcp`，并按 `profile-patch-snippet.yml` 在 DSH profile 的 `cordis.patch.yml` 注册 mcp-playwright（路径替换为本机实际路径；浏览器参数用 `chrome` 或 `chromium`）。

## 使用

**通常无需手动加载**：技能目录会在每个新会话自动注入，模型发现任务匹配就自动加载全文。新会话里直接说需求即可：

> 帮我配置学情阶段反馈模板，规则是任一天完课时长<100 算未完成。

需要强制触发时，点名技能即可（两种写法均可）：

- 消息中写「使用 learning-stage-feedback 技能」+ 需求
- TUI 斜杠命令：`/skill:learning-stage-feedback 附加指令`

模型会依次：自检浏览器工具 → 按五阶段协议追问需求 → 给出 SQL 确认稿 → 页面上完成配置、保存到服务器 → 三类学生测试。

## 常见问题

**为什么需要浏览器工具？** 配置操作发生在网页上，技能本身不注册工具；Playwright MCP 提供 `mcp__playwright__browser_*` 工具，本包的 install/verify 脚本负责供给与自检。

**Excel 会传到哪？** 网站说“Excel 仅在当前浏览器处理”，原始文件不上传。

**模板数据存在哪？** 网站上“保存到服务器”的模板全员共享、无个人隔离；删除/覆盖会影响所有老师。

**网站改版了怎么办？** 更新 `skills/learning-stage-feedback/SKILL.md`（重点：按钮名、模板机制、SQL 校验规则），无需重新安装工具。

**不用 DSH 的同事怎么用？** 把 `skills/learning-stage-feedback/resources/site-manual.md` 与 `sql-templates.md` 交给任意带浏览器的 AI（或当手册阅读）。

## License

MIT