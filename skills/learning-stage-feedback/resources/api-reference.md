# API 参考：学情阶段反馈模板库

本文件供 AI 执行写入时查阅。**不要整段粘贴给用户看**，向用户解释时使用第 6 节的“人话翻译”。

## 1. 端点

Base URL：`https://follow-class-reminder.pages.dev`

| 方法 | 路径 | 作用 | 成功状态码 |
|---|---|---|---|
| GET | `/api/learning-feedback/templates` | 列出全部共享模板（含完整配置） | 200 |
| POST | `/api/learning-feedback/templates` | 新建模板；服务端生成新 id | 201 |
| PUT | `/api/learning-feedback/templates/{id}` | 更新指定模板 | 200 |
| DELETE | `/api/learning-feedback/templates/{id}` | 物理删除模板 | 200 |
| GET | `/api/learning-feedback/builtin-templates` | 查询被隐藏的内置模板 | 200 |
| POST | `/api/learning-feedback/builtin-templates` | 隐藏内置模板 `{ "mode": "..." }` | 200 |

特性：

- 当前接口**没有鉴权**，CORS 允许 `*`，任何能联网的客户端都能调用。
- 模板库**全员共享**，没有个人隔离；POST/PUT/DELETE 立即影响所有老师。
- 服务端只保存模板 JSON，**不接触 Excel 数据**；SQL 在浏览器端对导入数据执行。
- 服务端校验 SQL 时**只做语法/结构校验，不实际执行**。因此 SQL 逻辑是否正确必须靠本地自检和老师在网站上验证。

## 2. GET 响应结构

```json
{
  "ok": true,
  "templates": [
    {
      "schemaVersion": 3,
      "id": "36244a8a-3ad1-4cf0-b363-e597c56dc382",
      "name": "模板名称",
      "missingRules": { "...": "..." },
      "blocks": [],
      "createdAt": "2026-08-16T00:00:00.000Z",
      "updatedAt": "2026-08-16T00:00:00.000Z"
    }
  ]
}
```

注意：GET 返回的配置会经过服务端归一化，缺省字段会被补齐。**PUT 修改时应以 GET 拿到的完整配置为底稿**，不要用几个月前保存的旧 JSON 直接覆盖。

## 3. POST/PUT 请求体（EditableCustomFeedbackTemplate）

请求体是 JSON，`Content-Type: application/json`，UTF-8。顶层字段：

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `schemaVersion` | number | 是 | 固定 `3` |
| `id` | string | 是 | POST 新建填 `""`；PUT 填目标模板真实 id |
| `name` | string | 是 | 模板名，trim 后 1~40 字 |
| `missingRules` | object | 是 | 四个键都要有，结构见下 |
| `blocks` | array | 是 | 1~40 个内容块 |

`missingRules` 固定结构（空值处理规则，四个键缺一不可）：

```json
{
  "completedMinutes": { "mode": "ignore", "value": 0 },
  "classAccuracy":     { "mode": "ignore", "value": 0 },
  "participationRate": { "mode": "ignore", "value": 0 },
  "exitAccuracy":      { "mode": "ignore", "value": 0 }
}
```

`mode` 取 `ignore`（忽略该行）或 `value`（按 `value` 计入平均值）。

### 3.1 内容块 `blocks[]`

内容块分两种，公共字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | string | 块唯一 id，建议 `block-` + 8 位随机十六进制 |
| `kind` | `"fixed"` 或 `"conditional"` | 固定句 / 条件句组 |
| `join` | `"blank-line"` / `"newline"` / `"inline"` | 与上一块之间：空一行 / 直接换行 / 紧接上一句 |
| `lists` | array | 该块可引用的查询对象，至少给 `[]` |

**fixed 块额外字段：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `text` | string | 固定话术，trim 后非空。可含 `ykt` 占位符和查询引用 |

**conditional 块额外字段：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `dimensions` | array | 1 个或多个条件维度 |
| `branches` | array | 分支话术，数量必须与维度展开后的分支数一致 |

`dimensions[]`：

```json
{ "metric": "completedMinutes", "thresholds": [80, 90], "includeMissing": true }
```

- `metric` 只取：`completedMinutes` / `classAccuracy` / `participationRate` / `exitAccuracy`（分别是平均完课时长、平均课堂答题正确率、平均课堂参与率、平均出门测正确率）。
- `thresholds` 会排序去重，可为 `[100]`、`[60, 85]` 等。
- `includeMissing` 可选，`true` 时把「-」单列一档。
- 同一个 conditional 块内，四个 metric 不能重复。

`branches[]`：`{ "key": "0", "text": "..." }`，`text` trim 后非空。

分支数量规则：

- 单维度、无 missing：`thresholds.length + 1` 个分支。
- 单维度、有 missing：`thresholds.length + 2` 个分支。
- 多维度：各维分支数相乘（笛卡尔积），key 用各维序号 `.` 连接，例如二维时 `0.0`、`0.1`、`1.0`、`1.1`。
- 设排序去重后的阈值为 `n` 个：key `0` = 小于最小阈值；key `1`~`n-1` = 各中间区间；key `n` = 大于等于最大阈值；若 missing 为 true，额外最后一个 key `n+1` = 「-」档。
- 例：`thresholds: [100], includeMissing: true`（n=1）→ 分支 key 依次 `0`（<100）、`1`（≥100）、`2`（「-」）。
- 例：`thresholds: [60, 85], includeMissing: false`（n=2）→ key `0`（<60）、`1`（60~85）、`2`（≥85）。

### 3.2 查询对象 `blocks[].lists[]`

`mode` 常用 `"sql"`。完整字段（都要给，避免旧数据迁移或前端异常）：

| 字段 | 类型 | 常用值 |
|---|---|---|
| `id` | string | 建议 `list-` + 8 位随机十六进制 |
| `name` | string | 查询名，trim 非空；同块内唯一；不能叫「全局数据」；不能含 `【】.:：｛｝{}` |
| `mode` | `"sql"` / `"row-variable"` / `"subject-summary"` / 旧版空串 | SQL 查询对象写 `"sql"` |
| `conditionMode` | `"all"` / `"any"` | SQL 对象通常 `"all"` |
| `conditions` | array | SQL 对象通常 `[]` |
| `itemFormat` | string | SQL 对象通常 `"【课次名称】"`（占位，不影响 SQL 输出） |
| `start` | number | `1` |
| `end` | number | `9999`（或限制条数） |
| `separator` | `"newline"` / `"comma"` / `"semicolon"` / `"custom"` | 多行连接方式：换行 / 顿号 / 分号 / 自定义 |
| `customSeparator` | string | `separator: "custom"` 时的连接符，如「和」 |
| `deduplicate` | boolean | 通常 `false` |
| `fallback` | string | 通常 `"暂无"` |
| `numbered` | boolean | 自动编号，**单值输出时必须 `false`** |
| `sorts` | array | SQL 对象通常 `[]` |
| `itemPrefix` | string | 每条前缀，通常 `""` |
| `itemSuffix` | string | 每条后缀，通常 `""` |
| `sql` | string | `mode: "sql"` 时的查询语句 |

注意：`itemFormat` 对 SQL 查询的输出没有实际渲染作用，但**字段必须存在**，沿用 `"【课次名称】"` 即可。

## 4. SQL 校验规则（服务端真实规则）

`validateLearningSql` 的规则如下，任一条不满足都会 400：

1. trim 后非空。
2. 必须以 `SELECT` 开头。
3. 必须包含 `FROM 全局数据`。
4. 不能包含 `;`。
5. 不能包含 `--`、`/*`、`*/`。
6. 禁止写入关键字：`INSERT UPDATE DELETE DROP ALTER CREATE REPLACE TRUNCATE MERGE INTO ATTACH DETACH USE SOURCE REQUIRE IMPORT EXPORT SCRIPT FUNCTION EVAL`。
7. 禁止 `->`、`@[` 等对象属性/JavaScript 扩展语法。
8. 函数白名单：`AVG MAX MIN SUM COUNT ROUND COALESCE IFNULL`；其他函数（如 `ABS`、`LEN`）报「暂不支持SQL函数」。
9. 语法通过 alaSQL parser：字段名用中文原名；`AND/&&`、`OR/||` 等价；全角逗号/分号会被转换；三个时长字段可省略「（分钟）」。
10. `GROUP BY` + `HAVING` 可用；**没有 GROUP BY 的 HAVING 会语法报错**，0 行隐藏句统一写 `GROUP BY 学生ID`。
11. `CASE WHEN` 条件不满足会返回一行 NULL（残句）；需要“不满足就不显示”时用 `GROUP BY ... HAVING` 返回 0 行。
12. SQL 常量里不要写 `ykt`——SQL 返回结果不做称呼替换，`ykt` 只写在话术文本里。

## 5. 一个已通过站点源码校验的完整模板示例

这个示例同时展示两种机制，可作为骨架：

- 开头固定句；
- 课堂参与用**条件句组**（规则落在“平均课堂参与率”上）；
- 出勤、出门测用 **SQL 条件行**（规则落在“任一天/每一行”上，0 行时整行隐藏，各分支互斥）。

**直接用前请按老师需求改话术和阈值。**

```json
{
  "schemaVersion": 3,
  "id": "",
  "name": "示例·课堂参与与出门测反馈",
  "missingRules": {
    "completedMinutes": { "mode": "ignore", "value": 0 },
    "classAccuracy": { "mode": "ignore", "value": 0 },
    "participationRate": { "mode": "ignore", "value": 0 },
    "exitAccuracy": { "mode": "ignore", "value": 0 }
  },
  "blocks": [
    {
      "id": "block-6f1a2b3c",
      "kind": "fixed",
      "join": "blank-line",
      "text": "ykt家长您好，跟您同步一下孩子这个阶段的学习情况～",
      "lists": []
    },
    {
      "id": "block-8e2c4d5a",
      "kind": "conditional",
      "join": "newline",
      "dimensions": [
        { "metric": "participationRate", "thresholds": [40, 80] }
      ],
      "branches": [
        { "key": "0", "text": "这个阶段孩子课上互动还比较少。别怕答错，下节课咱们先定个小目标：哪怕主动答一次题，也是进步。" },
        { "key": "1", "text": "课堂参与还有提升空间。孩子偶尔会跟着答，但还可以再放开一点，多举手、多出声，思路会越练越清楚。" },
        { "key": "2", "text": "这个阶段孩子课上答题很积极，基本每讲都跟着练了。这个状态对当堂吸收帮助很大，继续保持。" }
      ],
      "lists": []
    },
    {
      "id": "block-7b9e1f6d",
      "kind": "fixed",
      "join": "newline",
      "text": "【出勤完成.内容】\n【出勤未完成.内容】\n【出门测未完成.内容】\n【出门测优秀.内容】\n【出门测一般.内容】\n【出门测需加强.内容】",
      "lists": [
        {
          "id": "list-0c1d2e3f",
          "name": "出勤完成",
          "conditionMode": "all",
          "conditions": [],
          "itemFormat": "【课次名称】",
          "start": 1,
          "end": 9999,
          "separator": "newline",
          "customSeparator": "",
          "deduplicate": false,
          "fallback": "暂无",
          "mode": "sql",
          "numbered": false,
          "sorts": [],
          "itemPrefix": "",
          "itemSuffix": "",
          "sql": "SELECT '这段时间每一讲都按时出勤、完整听完，出勤习惯满分，继续保持！' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(完课时长) = COUNT(*) AND MIN(完课时长) >= 100"
        },
        {
          "id": "list-3e4f5a6b",
          "name": "出勤未完成",
          "conditionMode": "all",
          "conditions": [],
          "itemFormat": "【课次名称】",
          "start": 1,
          "end": 9999,
          "separator": "newline",
          "customSeparator": "",
          "deduplicate": false,
          "fallback": "暂无",
          "mode": "sql",
          "numbered": false,
          "sorts": [],
          "itemPrefix": "",
          "itemSuffix": "",
          "sql": "SELECT '有几讲没能完整听完，记得抽空补看回放，把知识点补上哦。' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(完课时长) < COUNT(*) OR MIN(完课时长) < 100"
        },
        {
          "id": "list-4f5a6b7c",
          "name": "出门测未完成",
          "conditionMode": "all",
          "conditions": [],
          "itemFormat": "【课次名称】",
          "start": 1,
          "end": 9999,
          "separator": "newline",
          "customSeparator": "",
          "deduplicate": false,
          "fallback": "暂无",
          "mode": "sql",
          "numbered": false,
          "sorts": [],
          "itemPrefix": "",
          "itemSuffix": "",
          "sql": "SELECT '还有出门测没有完成，记得及时补测哦。' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(出门测正确率) < COUNT(*)"
        },
        {
          "id": "list-8c9d0e1f",
          "name": "出门测优秀",
          "conditionMode": "all",
          "conditions": [],
          "itemFormat": "【课次名称】",
          "start": 1,
          "end": 9999,
          "separator": "newline",
          "customSeparator": "",
          "deduplicate": false,
          "fallback": "暂无",
          "mode": "sql",
          "numbered": false,
          "sorts": [],
          "itemPrefix": "",
          "itemSuffix": "",
          "sql": "SELECT '出门测也都认真完成了，成绩很亮眼！' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(出门测正确率) = COUNT(*) AND AVG(出门测正确率) >= 85"
        },
        {
          "id": "list-2a3b4c5d",
          "name": "出门测一般",
          "conditionMode": "all",
          "conditions": [],
          "itemFormat": "【课次名称】",
          "start": 1,
          "end": 9999,
          "separator": "newline",
          "customSeparator": "",
          "deduplicate": false,
          "fallback": "暂无",
          "mode": "sql",
          "numbered": false,
          "sorts": [],
          "itemPrefix": "",
          "itemSuffix": "",
          "sql": "SELECT '出门测都完成了，正确率还有提升空间，咱们抽空把错题过一遍，会越来越稳。' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(出门测正确率) = COUNT(*) AND AVG(出门测正确率) >= 60 AND AVG(出门测正确率) < 85"
        },
        {
          "id": "list-5e6f7a8b",
          "name": "出门测需加强",
          "conditionMode": "all",
          "conditions": [],
          "itemFormat": "【课次名称】",
          "start": 1,
          "end": 9999,
          "separator": "newline",
          "customSeparator": "",
          "deduplicate": false,
          "fallback": "暂无",
          "mode": "sql",
          "numbered": false,
          "sorts": [],
          "itemPrefix": "",
          "itemSuffix": "",
          "sql": "SELECT '出门测都交了，不过最近错题有点多。建议把错题按知识点再过一遍，遇到卡壳的地方随时问老师。' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(出门测正确率) = COUNT(*) AND AVG(出门测正确率) < 60"
        }
      ]
    }
  ]
}
```

这个模板的显示逻辑：课堂参与按平均参与率三选一；出勤按「任一天全勤 / 任一天未完成」二选一；出门测按「有缺测 / 全交且平均 ≥85 / 60~85 / <60」四选一。SQL 条件行使用 0 行隐藏机制，互相矛盾的两句不会同时出现。

## 6. 给用户看时的「人话翻译」

API 返回或错误不要直接抛给老师，翻译示例：

| 系统含义 | 对老师这样说 |
|---|---|
| 400，条件句组分支不完整 | 「这个条件我少分了一档，我补一下。」 |
| 400，SQL 语法有误 | 「这个判断条件我没写对，我调整一下。」 |
| 500，服务端异常 | 「网站接口暂时有点问题，我先停一下，稍后重试。」 |
| 成功 201 | 「模板已经保存到共享库了，您打开网站选它就能用。」 |
| 模板名重复 | 「线上已经有一个叫这个名字的模板，您看我是更新它，还是起个新名字？」 |

## 7. 请求示例

以下 `payload.json` 指第 5 节的完整模板 JSON 文件（UTF-8 无 BOM）。

### 7.1 PowerShell 5.1 / 7（Windows）

```powershell
# 查列表
curl.exe -s https://follow-class-reminder.pages.dev/api/learning-feedback/templates

# 新建（务必用 curl.exe，不是 curl 别名）
curl.exe -s -X POST "https://follow-class-reminder.pages.dev/api/learning-feedback/templates" `
  -H "Content-Type: application/json" `
  --data-binary "@payload.json"

# 修改
curl.exe -s -X PUT "https://follow-class-reminder.pages.dev/api/learning-feedback/templates/<模板ID>" `
  -H "Content-Type: application/json" `
  --data-binary "@payload.json"

# 删除（确认后）
curl.exe -s -X DELETE "https://follow-class-reminder.pages.dev/api/learning-feedback/templates/<模板ID>"
```

写无 BOM 文件（PowerShell 5.1 的 `Set-Content -Encoding UTF8` 会带 BOM）：

```powershell
$json = Get-Content -Raw payload.json  # 或由 AI 拼好字符串
[System.IO.File]::WriteAllText("$PWD\payload.json", $json, (New-Object System.Text.UTF8Encoding($false)))
```

### 7.2 bash / curl（Linux、macOS、Git Bash）

```bash
curl -s https://follow-class-reminder.pages.dev/api/learning-feedback/templates

curl -s -X POST "https://follow-class-reminder.pages.dev/api/learning-feedback/templates" \
  -H "Content-Type: application/json" \
  --data-binary "@payload.json"

curl -s -X PUT "https://follow-class-reminder.pages.dev/api/learning-feedback/templates/<模板ID>" \
  -H "Content-Type: application/json" \
  --data-binary "@payload.json"

curl -s -X DELETE "https://follow-class-reminder.pages.dev/api/learning-feedback/templates/<模板ID>"
```

### 7.3 Python（无第三方依赖）

```python
import json, pathlib, urllib.request

base = "https://follow-class-reminder.pages.dev/api/learning-feedback/templates"
payload = json.loads(pathlib.Path("payload.json").read_text(encoding="utf-8"))

def request(url, method="GET", data=None):
    body = json.dumps(data, ensure_ascii=False).encode("utf-8") if data is not None else None
    req = urllib.request.Request(url, data=body, method=method,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))

created = request(base, "POST", payload)
print(created["template"]["id"])

updated = request(f"{base}/{created['template']['id']}", "PUT", {**payload, "id": created["template"]["id"]})
print(updated["ok"])
```

### 7.4 幂等更新的安全顺序

1. GET 列表拿到目标 `id` 和完整 `config`。
2. 把本地改动合并进 `config`，不要从零生成后直接 PUT。
3. 本地备份旧 JSON。
4. PUT 后 GET 回读；若回读内容与预期不符，停下来报告，不要反复重试。
