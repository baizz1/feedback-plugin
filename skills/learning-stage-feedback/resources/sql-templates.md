# SQL 模板库（直接复制，替换条件即可）

> **条件分层原则**：规则落在“平均水平”→ 用条件句组（均值分档）；规则落在“任一天 / 任一行”（如任一天完课时长<100 即算未完成）→ 必须用本文件的 SQL 写法（0 行隐藏机制），均值分档会漏判/误判。站内 SQL 是 alaSQL 在浏览器内存里对 Excel 行执行的 SQL 式查询，不是标准 SQL。

## 状态判断类（单值返回，用于「课程：已完成√」这种行）

### 课程状态：任一天完课时长<100 或为空 → 未完成
SELECT CASE WHEN MIN(完课时长) >= 100 AND COUNT(完课时长) = COUNT(*) THEN '已完成√' ELSE '未完成×' END AS 状态 FROM 全局数据

### 出门测状态：任一天出门测正确率为空 → 未完成
SELECT CASE WHEN COUNT(出门测正确率) = COUNT(*) THEN '已完成√' ELSE '未完成×' END AS 状态 FROM 全局数据

## 条件行类（全部满足才输出文案，否则 0 行 → 整行隐藏）

### 全部完成才显示鼓励句（GROUP BY 学生ID 仅为满足校验，语义=全部一组）
SELECT '在众多同学中你已经脱颖而出了，未来继续保持，争取永不缺席！' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(完课时长) = COUNT(*) AND MIN(完课时长) >= 100 AND COUNT(出门测正确率) = COUNT(*)

## 明细列表类（列知识点/课次）

### 出门测正确率最低的 3 个知识点（不含未完成的）
SELECT 科目, 课次讲数, 课次名称, 出门测正确率 FROM 全局数据 WHERE 出门测正确率 IS NOT NULL AND 出门测正确率 < 80 ORDER BY 出门测正确率 ASC, 课次讲数 ASC LIMIT 3

### 设置了但未完成的出门测
SELECT 科目, 课次讲数 FROM 全局数据 WHERE 出门测总分 IS NOT NULL AND 出门测正确率 IS NULL ORDER BY 课次讲数 ASC

### 完课时长不足 100 分钟的讲次明细（任一天语义：列出具体哪几讲）
SELECT 课次讲数, 课次名称, 完课时长 FROM 全局数据 WHERE 完课时长 < 100 ORDER BY 课次讲数 ASC

### 按科目算综合分取前 2
SELECT 科目, ROUND(AVG(出门测正确率) * 0.6 + AVG(正确率) * 0.4, 2) AS 综合分 FROM 全局数据 GROUP BY 科目 HAVING COUNT(出门测正确率) > 0 AND COUNT(正确率) > 0 ORDER BY 综合分 DESC LIMIT 2

## 成套模板：出勤 + 出门测（6 条，任一天语义，2026-08 已实测）

规则：任一天完课时长<100 或有「-」→ 出勤有未完成；出门测任一天缺测 → 未完成；全部完成时按平均正确率分档（≥80 亮眼 / 60~79 提升空间 / <60 需巩固）。出门测正确率在 SQL 中为 0~100 数值。

用法：每个查询返回 1 行 1 字段「内容」，**取消「自动编号」**；块话术里每行放一个【查询名.内容】引用，查询 0 行 → 该行自动隐藏，两个维度各命中且仅命中一句。

- 出勤完成：SELECT '这段时间每一讲都按时出勤、完整听完，出勤习惯满分，继续保持！' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(完课时长) = COUNT(*) AND MIN(完课时长) >= 100
- 出勤未完成：SELECT '有几讲没能完整听完，记得抽空补看回放，把知识点补上哦。' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(完课时长) < COUNT(*) OR MIN(完课时长) < 100
- 出门测未完成：SELECT '还有出门测没有完成，记得及时补测哦。' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(出门测正确率) < COUNT(*)
- 出门测优秀：SELECT '出门测也都认真完成了，成绩很亮眼！' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(出门测正确率) = COUNT(*) AND AVG(出门测正确率) >= 80
- 出门测一般：SELECT '出门测都完成了，正确率还有提升空间，继续加油！' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(出门测正确率) = COUNT(*) AND AVG(出门测正确率) >= 60 AND AVG(出门测正确率) < 80
- 出门测需加强：SELECT '出门测都完成了，不过正确率还不理想，建议结合错题多巩固哦。' AS 内容 FROM 全局数据 GROUP BY 学生ID HAVING COUNT(出门测正确率) = COUNT(*) AND AVG(出门测正确率) < 60

> 依赖站点版本：含 SQL 的模板保存需要站点已部署“服务端校验跳过 SQL 执行”的修复；旧版站点保存必报 `Code generation from strings disallowed for this context`（详见 SKILL.md 第七节第 12 条）。

## 话术引用写法

- 单字段单行：课程：{课程状态.状态}
- 第 1 条：{查询名.字段名1}
- 第 1~3 条：{查询名.字段名1~3}
- 同行多字段循环：{低分课次.科目1~3第低分课次.课次讲数1~3讲：低分课次.课次名称1~3}
- 查询 0 行 → 引用该查询的整行隐藏（实现条件句）
- 学生称呼占位符：ykt（不带花括号）