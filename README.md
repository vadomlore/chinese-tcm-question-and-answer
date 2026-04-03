# 中医问答日卡工作流

这是一个偏稳态的工作流，不追求全自动操控 Copilot Chat，而是把最容易坏的部分降到最低。

## 目标

- 每天中午自动准备当天题库文件和提示文件
- 你在 Copilot Chat 里只执行一次 `/生成中医问答题`
- 当天问答文件写入 `data/daily/`
- 需要时用脚本自动提交并推送到 GitHub

## 工作流

1. Windows 计划任务在中午运行 `scripts/prepare_daily_prompt.ps1`
2. 该脚本会创建：
   - `data/daily/YYYY-MM-DD.md`
   - `prompts/daily/today-task.md`
3. 你打开 Copilot Chat，执行 `/生成中医问答题`
4. Copilot 会读取 `today-task.md`，把当天题目写进 `data/daily/YYYY-MM-DD.md`
5. 你确认无误后，运行 `scripts/publish_daily_cards.ps1`

## 为什么这样更稳

- 不依赖 UI 自动输入到 Copilot Chat 输入框
- 不依赖未公开的 Copilot 自动对话接口
- 每天真正手动的动作只有一次短命令
- 题库文件是纯 Markdown，后续网页读取和 GitHub 托管都简单

## 每日文件格式

每日题库文件放在 `data/daily/`，结构如下：

- Date / QuestionCount / FocusTopics / YesterdayFile
- Daily Context
- Daily Questions (AI Generated)
- Notes

这样后续网页端可以直接读取昨天的文件生成练习页。

## 脚本

- `scripts/prepare_daily_prompt.ps1`
  - 准备当天题库文件和 prompt 上下文文件
  - 可选自动打开 VS Code 工作区
- `scripts/register_daily_task.ps1`
  - 注册中午执行的 Windows 计划任务
- `scripts/publish_daily_cards.ps1`
  - 提交并推送当天题库文件到 GitHub

## 使用步骤

### 1. 注册计划任务

在 PowerShell 中运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\register_daily_task.ps1
```

### 2. 中午生成当天题库

计划任务会运行准备脚本。你也可以手动运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\prepare_daily_prompt.ps1 -OpenVSCode
```

### 3. 在 Copilot Chat 中执行短命令

直接输入：

```text
/生成中医问答题
```

如果当天想偏某类主题，可以补一句很短的话，例如：

```text
/生成中医问答题 今天偏经络和辨证
```

### 4. 发布到 GitHub

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish_daily_cards.ps1
```

## GitHub Pages 静态答题页

当前仓库已经改成 GitHub Pages 可部署的纯静态结构：

- `index.html`：站点入口
- `static/styles.css`：样式
- `static/app.js`：前端逻辑
- `data/index.json`：每日题库索引
- `data/daily/*.md`：每日题库文件

页面会优先读取目标日期之前最近一份有题目的日卡文件。如果前一天没有题目，会自动回退到更早的一份已有题库。

## 如何发布到 GitHub Pages

1. 把仓库推送到 GitHub
2. 打开仓库设置中的 Pages
3. Source 选择 `Deploy from a branch`
4. Branch 选择你的主分支，Folder 选择 `/ (root)`
5. 保存后，GitHub 会把仓库根目录当成静态站点发布

当前方案使用仓库设置中的 Pages 分支发布，不依赖 `.github/workflows/` 下的部署工作流。

## 站点使用逻辑

- 根页面会读取 `data/index.json`
- 再根据索引找到最近一份可练习的题库文件
- 点击“显示答案”展开答案、关键词和复习提示
- 如果还没有题目，会提示你先执行 `/生成中医问答题`

## 日常发布

生成题目后直接执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish_daily_cards.ps1
```

这个脚本会：

- 更新 `data/index.json`
- 提交当天题库和静态站点相关文件
- 推送到 GitHub

推送完成后，GitHub Pages 就会更新。