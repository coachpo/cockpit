# Cockpit

[English](README.md) | 简体中文

Cockpit 以 OpenAI 兼容 API 前置 Codex:它是一个 Go 代理,负责 Codex OAuth、请求转发与 websocket 中继,配置和鉴权状态可从 Nacos 热更新。交付形态是一个 Go 服务加可嵌入 SDK,外加 React 管理界面——本 monorepo 统一维护这一切。

## 目录结构

- `backend/` —— Go 服务与可嵌入 SDK:OAuth 流程、OpenAI 兼容接口、Nacos 配置/鉴权、websocket 中继
- `frontend/` —— React + Vite 管理界面
- `.github/workflows/` —— monorepo 的 CI、发布、Docker 镜像构建与清理

## 从哪里开始

```bash
git clone git@github.com:coachpo/cockpit.git
```

- 改后端或 API:从 `backend/AGENTS.md` 入手——后端采用 AGENTS 优先的文档方式,刻意不单独放 README
- 改前端:从 `frontend/AGENTS.md` 或 `frontend/README.md` 入手
- 前端暴露了什么、哪些只存在于管理 API、`/v1` 消费者用什么:见 [USER_FUNCTIONS.md](./USER_FUNCTIONS.md)

## 常用命令

```bash
go -C backend test ./...
pnpm --dir frontend lint
pnpm --dir frontend build
```

## 说明

- GitHub 实际执行的是根目录 `.github/workflows/` 里的工作流;各服务目录内的工作流副本仅作参考。
- `authjson/`、`docs/`、`.sisyphus/` 是 gitignore 掉的本地草稿目录,不是产品文档。
