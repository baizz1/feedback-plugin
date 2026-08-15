---
name: learning-stage-feedback
description: 学情阶段反馈网站（follow-class-reminder.pages.dev/learning-stage-feedback）的配置与评语模板制作助手。内含浏览器工具编排（Playwright MCP 端到端操作序列与自检）、现场状态识别与临时决策清单、数据模型、SQL 规则与需求追问协议；任务开始先做工具可用性自检，无浏览器工具时走降级路径。
whenToUse: 用户提到学情阶段反馈、家长反馈评语、评语模板、出门测/完课时长判断、ykt 占位符、管理模板，或要求在该网站配置/修改/测试反馈模板时。
---

# 学情阶段反馈 · 评语模板制作助手（含浏览器工具编排）

## 0. 执行前提（先读）

本技能的操作对象是网页应用。**执行配置任务必须依赖浏览器自动化工具**（工具名形如 mcp__playwright__browser_*，由 Playwright MCP 提供）。skill 本身只提供知识与编排，不注册工具。

### 0.1 工具可用性自检（每项任务开始时必做）
1. 检查本会话工具列表是否有 browser_navigate / browser_click / browser_type / browser_file_upload / browser_snapshot 等浏览器工具。
2. 有 → 按第六节编排执行。
3. 没有 → 走第九节降级路径：明确告知用户浏览器工具未配置，请其运行插件包内 install.ps1（Windows）或按 README 安装，然后新开会话再执行。**没有浏览器工具时不要假装能操作网页。**

### 0.2 插件包结构（分发时随本技能携带）
- skills/learning-stage-feedback/（本技能）
- install.ps1 / verify.ps1 / profile-patch-snippet.yml（浏览器工具供给：安装 + 配置 + 自检）
- README.md（安装与使用说明）

## 一、网站与页面

- 线上：https://follow-class-reminder.pages.dev/learning-stage-feedback
- 首页（跟课提醒）：/ ；作业点评：/homework-review；错题导出：/ykt-error-export；资料下载：/resource-downloads
- 本地开发版（未部署时）：http://localhost:3010/learning-stage-feedback，功能与线上一致。

## 二、数据模型（必须记住）

1. **全局数据 = 当前选中学生 + 当前反馈范围的全部有效行**，不是整份 Excel；切换学生后同一条 SQL 自动查下一名学生。
2. 聚合统计天然就是“当前学生这一组”——**无需 GROUP BY 学生ID**（除非校验器要求）。
3. Excel 的「-」= SQL NULL；百分比 0~100（80% 写 80）。
4. 出勤率 = 完课时长÷120×100；课堂参与率 = 答题数÷总题数×100。
5. 「补01」等补课讲次被反馈范围排除；阶段反馈范围 = 第1讲至该学生最高讲次（自适应）；单讲反馈 = 指定讲次。
6. 可用字段：学生ID、学生姓名、课次讲数、课次名称、科目、专属辅师、出勤时长（分钟）、回放观看时长（分钟）、完课时长（分钟）、出勤率、答题数、答题正确数、总题数、正确率、课堂参与率、出门测得分、出门测总分、出门测正确率。

## 三、SQL 硬性规则

- 只允许一条 SELECT，FROM 全局数据；末尾无分号；无注释；字段用 Excel 原始中文名。
- 支持：AVG/MAX/MIN/SUM/COUNT/ROUND/COALESCE/IFNULL、CASE WHEN、GROUP BY/HAVING、ORDER BY、LIMIT；AND/&&、OR/|| 等价。
- 聚合后筛选必须用 HAVING；空值用 IS NULL / IS NOT NULL。
- **不带 GROUP BY 的 HAVING 校验报错**；CASE WHEN 条件不满足返回 1 行 NULL（不隐藏整行）；要“0 行隐藏”必须 GROUP BY + HAVING。
- ykt 占位符写 **ykt（不带花括号）**；查询引用：查询名.字段名 / .字段名1 / .字段名1~3；同行多字段用 { } 循环；查询 0 行→整行隐藏。
- 自动编号默认勾选，单值输出时取消。

### 3.1 条件分层：整体用「均值分档」，逐行用「SQL」

评语的判断条件分两层，收集需求时先问清属于哪一层，再选对机制：

- **整体水平 → 条件句组**：规则落在“平均水平”上（如平均完课时长 <100 分钟、平均出门测正确率 ≥80%），用「条件句组」（全局平均指标 + 分界值 + 区分 -）。操作简单、分支所见即所得，适合大多数阶段反馈。
- **某一天 / 某一行 → SQL 对象**：规则落在“任一行”上（如**任一天完课时长<100 即算未完成**、出门测任一天缺测），均值分档会漏判/误判——平均 ≥100 但某讲只有 24.8 分钟的学生会被误夸成“出勤满分”。必须改用 SQL：`SELECT '句子' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(完课时长) = COUNT(*) AND MIN(完课时长) >= 100`（0 行 → 引用该查询的整行隐藏）。成套写法见 resources/sql-templates.md「出勤 + 出门测成套模板」。

判别口诀：**问“平均”还是“任一天”**。老师说“平均水平如何如何”→ 均值分档；说“只要有一天 / 有一讲没达到就算”→ SQL。

注意：站内 SQL **不是标准 SQL**，而是网站在浏览器内存里对 Excel 行数据执行的 SQL 式查询（alaSQL 引擎），只支持本文件第三节列出的子集，不要按数据库语法写。

## 四、辅助老师制作评语的标准流程（五阶段协议）

阶段1 收集需求（先问清，不猜）：反馈对象、模板名称、反馈范围、话术原文、判断规则（阈值/边界/空值/AND-OR）、ykt 称呼、固定句与条件句、输出形式。缺失必问，不自行补规则。
阶段2 复述 + 追问缺口，等确认。
阶段3 输出最终确认稿：需求复述、模板结构表、查询对象、SQL、话术引用、逐点击步骤、预期结果、测试案例、保存与回退。
阶段4 页面执行（见第六节编排）。
阶段5 测试与交付：三类学生验证，核对各行与条件句显隐，验证「下个学生」沿用模板。

## 五、常用 SQL 模板

课程状态（任一天<100 或空→未完成）：SELECT CASE WHEN MIN(完课时长) >= 100 AND COUNT(完课时长) = COUNT(*) THEN '已完成√' ELSE '未完成×' END AS 状态 FROM 全局数据

出门测状态（任一天为空→未完成）：SELECT CASE WHEN COUNT(出门测正确率) = COUNT(*) THEN '已完成√' ELSE '未完成×' END AS 状态 FROM 全局数据

全部完成才显示鼓励句（0 行隐藏）：SELECT '在众多同学中你已经脱颖而出了，未来继续保持，争取永不缺席！' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(完课时长) = COUNT(*) AND MIN(完课时长) >= 100 AND COUNT(出门测正确率) = COUNT(*)

> 成套「出勤 + 出门测」模板（6 条查询，覆盖任一天/缺测/三档全分支，已实测）见 resources/sql-templates.md。

## 六、浏览器工具编排（端到端操作序列）

按顺序调用浏览器工具（具体调用形式以当前会话的工具访问方式为准）：

1. browser_navigate 打开直达页，核对标题含「学情阶段反馈」。
2. browser_snapshot 记录初始元素，**先按第七节识别页面状态**（UI 世代、导入状态）。
3. 导入 Excel：browser_click 点可见的「点击选择或拖入 Excel」按钮（不要点隐藏的 Choose File input）→ 文件选择器 modal 出现 → browser_file_upload 选择 Excel。
   - 若报文件在允许根目录之外：先用 shell 把 Excel 复制到报错信息列出的 allowed root，再上传。
   - 等待快照出现「已识别工作表“学情阶段反馈”，表头位于第 N 行」与「N 名学生 / M 条记录 / K 个课次」。
4. 选反馈方式（阶段反馈默认 / 单讲反馈需选讲次）→ browser_click「进入反馈工作台」。
5. 定位学生：browser_type 在「搜索学生」输入姓名或 ID → browser_click 选中。
6. 配置模板：browser_click「管理模板」（或导入页顶部「管理共享模板」）→ 弹窗「共享模板管理」→「新增」→ browser_type 填模板名称 → 逐块：
   - browser_click「固定句」/「条件句组」新建块；browser_type 填块话术；
   - browser_click 该块「新增查询」→ browser_type 填查询名称与 SQL → 等「校验通过 · 返回 …」出现（「保存查询」可用）→ 单值输出时取消「自动编号」→ browser_click「保存查询」。
7. browser_click「保存到服务器」→ 等提示「共享模板已保存」→ browser_click「关闭模板管理」。
8. browser_click 反馈区模板选择器 → 下拉选该模板 → browser_snapshot 核对评语。
9. 三类学生测试：逐个 browser_type 搜索 + browser_click 选中 + browser_snapshot 核对。
10. 顺带验证「下个学生」沿用模板、复制评语。

## 七、现场状态识别与临时决策（遇到奇怪问题时）

原则：**先快照观察 → 小步尝试 → 每步验证 → 拿不准就停下向用户说明并给选项**，不要连续盲点。

1. **识别网站 UI 世代**：反馈区是「模板选择器下拉（新版）」还是「5 个话术模式按钮：综合模板/阶段详评/完课反馈/进度激励/简短说法（旧版）」？按实际 UI 操作，不要照搬按钮名。新版有「管理模板/保存到服务器/同步」；旧版有「设为默认/换种说法/进展到第N天」。
2. **本地 vs 线上**：地址是 localhost:3010 还是 pages.dev？localhost 连接被拒说明本地未启动，改用线上。
3. **导入状态**：快照里有没有「已识别工作表…」？浏览器上下文重置（断网/重启）后需重新导入 Excel。
4. **按钮 disabled**：「保存查询」置灰 = SQL 校验失败（读校验文本改 SQL）；「换种说法」置灰属正常（仅部分模式可用）。
5. **ref 失效**：页面刷新/切换后 ref 会变——每次操作前重新 snapshot 拿新 ref，不要复用旧 ref。
6. **modal 卡住**：文件选择器打开期间其它工具报 “does not handle the modal state”——先 browser_file_upload 收尾；误开的对话框点关闭按钮或按 Escape。
7. **上传路径被拒**：报错信息会列出 allowed roots，把文件复制进去再传；Excel 被 Office 占用时用共享读方式复制（打开文件时允许 FileShare.ReadWrite）。
8. **浏览器工具连接异常**：报连接错误 → 重新 browser_navigate；MCP 进程死了 → 让用户重启 GUI 或运行 verify.ps1。
9. **Excel 表格差异**：表头行、字段名、空值写法（- 或空）可能不同——先用 openpyxl 读表头确认列名与表头行，SQL 字段名以实际 Excel 为准。
10. **线上共享**：保存前确认模板名不与他人冲突；删除/覆盖影响所有老师。
11. **其它脚本坑**：给别人机器写 .ps1 用纯 ASCII 输出（Windows PowerShell 5.1 会把无 BOM 的 UTF-8 中文脚本读乱）。
12. **含 SQL 的模板保存报 400 `Code generation from strings disallowed for this context`**：旧版网站的服务端校验会执行一次 SQL，而 Cloudflare Pages 的 V8 运行时禁止 new Function，导致**任何**含 SQL 的模板都无法保存（与 SQL 内容无关，最简 SELECT 也失败；客户端校验和预览都正常）。站点源码已修复（`validateCustomTemplate` 增加 `executeSql` 选项，templates 的两个 API 路由传 `{ executeSql: false }` 跳过服务端执行，SQL 本就在浏览器内对 Excel 行执行）。**站点更新部署后即可正常保存含 SQL 的模板**；若站点还没更新，先用「条件句组」近似，并向用户说明均值分档与任一天语义的差异（漏判/误判人数可先用 openpyxl 按阈值模拟算出再报告）。
13. **未知情况**：记录观察到的事实（快照文本、报错原文），向用户报告并给出 2~3 个可行选项再继续。

详细操作细节与已知坑见 resources/browser-ops.md。

## 八、测试学生定位方法
用 Python openpyxl 读 Excel 的「学情阶段反馈」工作表（表头第 3 行；第 9 列完课时长、第 16 列出门测正确率），按学生聚合出：全完成 / 任一天<100 / 任一天空值(-) / 边界（恰好 100、99.98）四类代表，再在页面搜索姓名或 ID 核对。

## 九、降级路径（无浏览器工具时）
1. 告知用户浏览器工具未配置，请其运行插件包 install.ps1（Windows）或按 README 安装，完成后新开会话。
2. 等待期间仍交付价值：完成五阶段需求确认与 SQL 设计，输出「最终确认稿 + 人工逐步操作说明」（精确到按钮名、输入内容、保存动作、验证方法），由用户手动完成或交给有浏览器的其它工具。

## 十、资源索引
- resources/browser-ops.md：浏览器操作细节与坑（上传、modal、点击、校验等待）
- resources/site-manual.md：网站功能全景与经验手册
- resources/sql-templates.md：SQL 模板库与话术引用写法