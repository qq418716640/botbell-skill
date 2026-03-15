[English](README.md) | [中文](README.zh-CN.md)

# BotBell Skill

从 AI 编程助手向你的 iPhone/Mac 发送推送通知 —— 并获取回复。

支持 [Claude Code](https://claude.ai/code)、[GitHub Copilot](https://github.com/features/copilot)、[Cursor](https://cursor.com)、[OpenAI Codex](https://openai.com/codex)、[Gemini CLI](https://github.com/google-gemini/gemini-cli)，以及所有支持 [Agent Skills](https://agentskills.io) 的工具。

## 功能

安装后，你的 AI 助手可以：

- **通知你** 耗时任务完成时（测试、构建、部署）
- **请求确认** 执行风险操作前（删除、强制推送、生产部署）
- **发送报告** （代码审查、分析结果）到你的手机
- **提问等待** 你回复后再继续工作

## 安装

```bash
npx skills add qq418716640/botbell-skill
```

## 前置条件

- 系统需安装 `curl` 和 `jq`

## 配置

1. 从 App Store 下载 [BotBell](https://botbell.app)
2. 创建一个 Bot 并复制其 Token
3. 设置环境变量：

```bash
export BOTBELL_TOKEN="bt_your_token_here"
```

## 使用

直接告诉你的 AI 助手你想做什么：

- "跑完测试后通知我"
- "部署到生产环境前先跟我确认"
- "审查这段代码，把摘要发到我手机上"
- "问我要用哪个配置"

Skill 会自动处理 —— 你的 AI 知道何时以及如何通知你。

## 手动调用

你也可以直接调用：

```
/botbell 执行数据迁移，完成后告诉我结果
```

## 需要更多功能？

如需多 Bot 管理、PAT 认证和更深度的集成，请使用 [BotBell MCP Server](https://github.com/qq418716640/botbell-mcp)。

## 链接

- [BotBell 官网](https://botbell.app)
- [BotBell MCP Server](https://github.com/qq418716640/botbell-mcp)
- [API 文档](https://botbell.app/docs/api)
