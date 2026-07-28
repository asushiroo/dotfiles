# Skill 说明索引

本文按当前环境可用能力整理；同名的 `drawio-skill` 只记录一次。

## 通用内置技能

| Skill | 作用 |
| --- | --- |
| `imagegen` | 生成或编辑位图素材，例如插画、照片、纹理和透明背景图片。 |
| `openai-docs` | 查询并引用 OpenAI 官方文档，帮助选择模型或使用 OpenAI/Codex API。 |
| `plugin-creator` | 创建、补全或更新 Codex 插件及其 marketplace 清单。 |
| `skill-creator` | 设计或改进 Codex skill 的结构、说明和工作流。 |
| `skill-installer` | 从官方列表或 GitHub 仓库安装 skill。 |
| `find-skills` | 根据需求查找可能已有的可安装 skill。 |

## 工程规划、架构与实现

| Skill | 作用 |
| --- | --- |
| `ask-matt` | 根据当前情况推荐合适的本仓库 skill 或工作流。 |
| `implement` | 按已有规格或任务单实现一项工作。 |
| `wayfinder` | 将跨多个会话的大型工作拆成可逐项解决的决策任务地图。 |
| `to-spec` | 将当前对话直接沉淀为规格，并发布到项目问题跟踪器。 |
| `to-tickets` | 将计划、规格或对话拆成带依赖关系的可执行任务单。 |
| `to-questionnaire` | 把暂时无法回答的决策整理为供他人填写的问卷。 |
| `request-refactor-plan` | 通过访谈制定小步提交的重构计划，并创建 GitHub Issue。 |
| `codebase-design` | 用“深模块”方法设计模块接口、边界和可测试性。 |
| `improve-codebase-architecture` | 扫描代码库中的架构深化机会，生成可视报告并讨论取舍。 |
| `design-an-interface` | 并行提出多套差异明显的模块/API 设计供比较。 |
| `domain-modeling` | 明确领域概念、术语与架构决策，维护领域模型。 |
| `ubiquitous-language` | 从对话提炼 DDD 通用语言表，标出歧义并统一术语。 |
| `prototype` | 编写一次性原型，以验证状态模型、逻辑或界面方向。 |
| `tdd` | 以测试驱动方式开发功能或修复问题。 |
| `setup-ts-deep-modules` | 为 TypeScript 项目配置 dependency-cruiser，约束包的深模块边界。 |

## 诊断、评审与质量

| Skill | 作用 |
| --- | --- |
| `diagnosing-bugs` | 用系统化循环诊断疑难故障、报错和性能回退。 |
| `code-review` | 从“是否符合规范”和“是否符合需求”两条线并行审查变更。 |
| `qa` | 进行交互式 QA：收集问题、补充代码库背景并创建 GitHub Issue。 |
| `triage` | 对 Issue 和外部 PR 分类、验证、追问并产出可交接的简报。 |
| `migrate-to-shoehorn` | 将测试中的 TypeScript `as` 断言迁移至 `@total-typescript/shoehorn`。 |
| `setup-matt-pocock-skills` | 初始化工程工作流所需的问题跟踪器、分类标签和领域文档结构。 |
| `setup-pre-commit` | 配置 Husky、lint-staged、格式化、类型检查和测试的提交前钩子。 |
| `git-guardrails-claude-code` | 为 Claude Code 配置拦截危险 Git 命令的安全钩子。 |
| `resolving-merge-conflicts` | 处理进行中的 Git merge 或 rebase 冲突。 |

## 调研、文档与协作

| Skill | 作用 |
| --- | --- |
| `research` | 基于高可信一手来源调研，并把结论写成仓库内 Markdown。 |
| `obsidian-vault` | 搜索、创建和整理 Obsidian 笔记、双链和索引。 |
| `drawio-skill` | 绘制流程图、架构图等 draw.io 图，并导出 PNG/SVG/PDF。 |
| `handoff` | 将当前对话压缩成可供另一位代理继续工作的交接文档。 |
| `claude-handoff` | 立即将当前工作交接给新的后台代理继续执行。 |
| `teach` | 在当前工作区内讲解新技能或概念，并配合练习。 |
| `scaffold-exercises` | 创建带题目、答案和讲解的练习目录结构。 |
| `wizard` | 生成交互式 Bash 向导，指导人工完成配置、迁移或状态切换。 |

## 访谈与决策打磨

| Skill | 作用 |
| --- | --- |
| `grilling` | 针对计划、决策或想法进行高强度追问和压力测试。 |
| `grill-me` | 通过连续访谈打磨一个计划或设计。 |
| `grill-with-docs` | 在追问打磨方案的同时产出 ADR 和术语文档。 |
| `batch-grill-me` | 每轮集中提出所有关键问题，适合快速暴露决策盲点。 |
| `loop-me` | 在当前工作区内持续追问待构建工作流的规格。 |

## 写作技能

| Skill | 作用 |
| --- | --- |
| `writing-fragments` | 探索阶段：收集和挖掘原始写作片段，暂不组织结构。 |
| `writing-beats` | 将素材编排为循序展开的叙事/论述节点。 |
| `writing-shape` | 将素材逐段塑造成完整文章。 |
| `edit-article` | 重组文章结构、提高清晰度并压缩冗余表达。 |
| `writing-great-skills` | 提供编写和编辑高质量 skill 的原则与术语参考。 |

## 快速选择

- “这段代码为什么坏了？”：`diagnosing-bugs`；“先写测试再修”：`tdd`。
- “帮我评审这组改动”：`code-review`；“把问题整理成 Issue”：`qa` 或 `triage`。
- “先想清楚怎么做”：`grilling`、`design-an-interface`、`to-spec`。
- “把大计划变成可实施工作”：`wayfinder`、`to-tickets`、`implement`。
- “需要图或文档”：`drawio-skill`、`research`、`obsidian-vault`。
