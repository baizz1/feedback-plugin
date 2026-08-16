# 评语预览清单（feedback-preview manifest）

> 可选扩展协议：仅当宿主是 DeepSeek Harness 且已确认启用 `@deepseek-ai/dsh-client-ui-feedback-preview` 客户端插件时使用。其他 agent 宿主应忽略本文件，不要输出 `feedback-preview` 代码块。

本文档供 AI 在模板写入成功后生成「不同情况评语看板」时查阅。DeepSeek Harness 若安装了 `@deepseek-ai/dsh-client-ui-feedback-preview` 插件，会把最终回复里的 `feedback-preview` 代码块渲染成消息下方的可展开看板，老师不用回网站也能先检查所有分支。

## 1. 什么时候输出

**前置条件**：当前宿主是 DeepSeek Harness，且已确认启用 `ui-feedback-preview` 客户端插件。无法确认时按未启用处理。

满足前置条件时，每次 POST（新建）或 PUT（修改）成功且 GET 回读核对通过后，**在最终回复里输出一个 `feedback-preview` 围栏代码块**。不要输出 JSON 文件路径代替，不要把代码块省略成一句“已生成预览”。

修改模板后必须重新生成完整清单，覆盖修改后的全部分支，不能只列改动的那一句。

## 2. 输出格式

```text
```feedback-preview
{
  "schema": "learning-stage-feedback-preview/v1",
  "templateName": "模板名",
  "templateId": "回读得到的模板 id",
  "generatedAt": "ISO 8601 时间",
  "cases": [
    {
      "id": "all-full-and-excellent",
      "title": "全勤 + 出门测优秀",
      "condition": "每讲完课时长≥100分钟；出门测全交且平均正确率≥85",
      "expectedLines": [
        "该情况下会完整出现的评语行……",
        "可以有多行，顺序与模板一致"
      ]
    }
  ]
}
```
```

规则：

- 围栏语言必须是 `feedback-preview`（也接受 `feedback-preview.json`）。
- `schema` 固定 `learning-stage-feedback-preview/v1`。
- `templateName` 与线上模板名完全一致。
- `templateId` 必须写 POST/PUT 回读到的真实 id；无 id 的降级场景不要编造，可省略。
- `cases` 至少 1 个，每个 case 的 `id/title/condition/expectedLines` 都非空；`id` 唯一，建议用 ASCII slug。
- `expectedLines` 写**该情况下会真实出现的完整评语行**，不要用省略号代替实际内容；动态明细部分写清占位结构即可，例如「第X讲（XX分钟）」。
- `condition` 用老师能看懂的中文，写清「平均」还是「任一天」、阈值边界和缺测规则，不要出现 SQL/JSON 字段名。

## 3. cases 覆盖要求（缺一不可）

1. **每个互斥分支至少 1 个 case**：条件句组每一档、SQL 0 行隐藏的每种命中情况都要出现。
2. **问题型**：出勤缺记录、出门测缺测、任一天完课时长<100、平均分低等，各给 1 个 case。
3. **全优型**：所有条件都满足时给 1 个 case。
4. **边界值**：每个阈值恰好命中都要有 case。例如阈值 85，必须有一个 case 写明“平均正确率=85”，并说明它落在哪一档。
5. **组合型**：出勤和出门测可能同时命中提醒句时，至少给 1 个组合 case。
6. case 顺序建议：全优 → 单项问题 → 边界值 → 组合问题。

## 4. 输出前自检

- [ ] 是合法 JSON，围栏内没有额外说明文字。
- [ ] schema、模板名、id 与线上回读一致。
- [ ] 每个分支都在 cases 里，且没有两个 case 命中同一组条件却给出矛盾预期。
- [ ] `expectedLines` 顺序与模板块顺序一致。
- [ ] 没有把 `ykt` 替换成具体姓名；保留占位符原样。
- [ ] 没有为了“显得多”而编造不存在的情况。

## 5. 完整示例

以下示例对应「高一第一次月假·出勤与出门测反馈（家长版）」模板，实际生成时请按当时模板替换为完整原文。

```text
```feedback-preview
{
  "schema": "learning-stage-feedback-preview/v1",
  "templateName": "高一第一次月假·出勤与出门测反馈（家长版）",
  "templateId": "a6363859-a698-4a4a-bbc6-5a259df2ce39",
  "generatedAt": "2026-08-16T07:05:59Z",
  "cases": [
    {
      "id": "all-full-and-excellent",
      "title": "全勤 + 出门测优秀",
      "condition": "每讲完课时长≥100分钟；出门测全交且平均正确率≥85",
      "expectedLines": [
        "📚 出勤：这个月每一讲都完整跟下来了，出勤率拉满，高一刚开学能保持这个节奏，很不容易。",
        "📝 出门测：都按时交了，平均正确率在 85 以上，说明当堂吸收得挺扎实，这个状态请继续保持。",
        "🗓 月假安排：出门测成绩很稳，这个月假以调整和预习为主。每天 30 到 40 分钟翻翻下个月的数学函数和物理运动学，别把状态断了就行。"
      ]
    },
    {
      "id": "attendance-missing",
      "title": "有缺勤记录",
      "condition": "至少一讲完课时长为空；或都有记录但存在讲次<100分钟且平均出勤率<60",
      "expectedLines": [
        "📚 出勤：这个月出勤率明显偏低，缺的课会直接影响后面函数、运动学这些连续内容。月假必须优先补回放，有看不懂的地方随时找辅师，别攒着。",
        "📚 需要补看的课：第X讲（XX分钟）……",
        "🗓 月假补课：这个月有课没听满 100 分钟，月假前三天优先补回放，边看边记卡住的地方，返校后直接问老师。"
      ]
    },
    {
      "id": "exit-missing",
      "title": "出门测有缺测",
      "condition": "至少一讲出门测正确率为空",
      "expectedLines": [
        "📝 出门测：这个月还有出门测没完成。麻烦您提醒孩子月假里抽空补上，这样老师才能准确判断他哪里会了、哪里还欠一点。",
        "📝 还没完成的出门测：第X讲……",
        "🗓 月假安排：第一件事是把缺的出门测补上，补完后再把错题过一遍，老师才能准确判断哪里会了、哪里还欠着。"
      ]
    },
    {
      "id": "boundary-85",
      "title": "边界：出门测平均恰好85",
      "condition": "出门测全交，平均正确率=85",
      "expectedLines": [
        "📝 出门测：都按时交了，平均正确率在 85 以上，说明当堂吸收得挺扎实，这个状态请继续保持。"
      ]
    },
    {
      "id": "boundary-60",
      "title": "边界：出门测平均恰好60",
      "condition": "出门测全交，平均正确率=60",
      "expectedLines": [
        "📝 出门测：都按时交了，平均正确率在 60 到 85 之间，基础还行，但还有几个点没吃透。月假里把错题按知识点过一遍，会比刷新题更管用。"
      ]
    }
  ]
}
```
```

## 6. 与浏览器端插件的关系

- 插件只解析和渲染，不执行 SQL，也不访问反馈网站。
- 插件默认折叠卡片，老师点开可看到每个 case 的标题、触发条件和预期评语。
- 插件找不到合法代码块时什么都不显示，不会影响正常对话。
- 网站上的实际渲染仍是最终事实来源；manifest 是给老师快速验收所有分支用的。
