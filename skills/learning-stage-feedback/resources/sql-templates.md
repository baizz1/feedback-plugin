# SQL 模板库（直接复制，替换条件即可）

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

### 按科目算综合分取前 2
SELECT 科目, ROUND(AVG(出门测正确率) * 0.6 + AVG(正确率) * 0.4, 2) AS 综合分 FROM 全局数据 GROUP BY 科目 HAVING COUNT(出门测正确率) > 0 AND COUNT(正确率) > 0 ORDER BY 综合分 DESC LIMIT 2

## 话术引用写法

- 单字段单行：课程：{课程状态.状态}
- 第 1 条：{查询名.字段名1}
- 第 1~3 条：{查询名.字段名1~3}
- 同行多字段循环：{低分课次.科目1~3第低分课次.课次讲数1~3讲：低分课次.课次名称1~3}
- 查询 0 行 → 引用该查询的整行隐藏（实现条件句）
- 学生称呼占位符：ykt（不带花括号）