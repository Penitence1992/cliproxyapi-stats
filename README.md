# CliproxyAPI Stats

macOS 菜单栏应用，实时监控 Claude 和 ChatGPT/Codex 账号的 API 额度使用情况。

> 本项目为 [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) 的配套监控工具。CLIProxyAPI 是一个多账号 API 代理服务，将多个 Claude / ChatGPT 账号统一为标准 OpenAI 接口对外提供服务。

## 功能

- **多账号监控**：同时监控多个 Claude / ChatGPT / Codex 账号
- **Claude 额度**：显示 5 小时和 7 天滚动窗口用量（通过 Anthropic OAuth API）
- **ChatGPT/Codex 额度**：显示 5 小时和周额度（通过 ChatGPT Web API）
- **按类型汇总**：菜单栏下拉面板按账号类型（claude / codex 等）分组展示平均剩余量
- **自动刷新**：可配置刷新间隔（默认 5 分钟）
- **文件监听**：账号目录变化时自动重新加载
- **开机启动**：支持登录时自动启动

## 系统要求

- macOS 13+

## 安装

从 [Releases](../../releases) 页面下载最新版 `.zip`，解压后将 `CliproxyAPI Stats.app` 拖入 `/Applications`。

> **首次打开提示"无法打开"？** 这是 macOS Gatekeeper 的安全限制。在终端执行以下命令后即可正常打开：
> ```bash
> xattr -cr "/Applications/CliproxyAPI Stats.app"
> ```
> 或者：右键点击 app → 打开 → 点击"打开"。

## 账号配置

在账号目录下为每个账号创建一个 JSON 文件（默认目录：`~/.cliproxyapi-stats/accounts/`，可在设置中修改）。

### Claude 账号

```json
{
  "access_token": "sk-ant-oat01-...",
  "email": "your@email.com",
  "type": "claude",
  "expired": "2026-12-31T00:00:00+08:00",
  "id_token": "",
  "last_refresh": "2026-03-23T00:00:00+08:00",
  "refresh_token": "sk-ant-ort01-..."
}
```

`type` 字段包含 `claude`（大小写不敏感）即走 Claude OAuth API。

### ChatGPT / Codex 账号

```json
{
  "access_token": "eyJhbGci...",
  "account_id": "org-xxxx",
  "email": "your@email.com",
  "type": "codex",
  "disabled": false,
  "expired": "2026-12-31T00:00:00+08:00",
  "id_token": "...",
  "last_refresh": "2026-03-23T00:00:00+08:00",
  "refresh_token": "..."
}
```

### 字段说明

| 字段 | 必填 | 说明 |
|------|------|------|
| `access_token` | ✅ | Bearer Token，用于 API 鉴权 |
| `email` | ✅ | 账号邮箱，用于界面展示 |
| `type` | ✅ | 账号类型，含 `claude` 走 Claude 接口，其余走 ChatGPT 接口 |
| `expired` | 可选 | Token 过期时间（ISO 8601），缺失则视为永久有效 |
| `disabled` | 可选 | `true` 时跳过该账号 |
| `account_id` | 可选 | ChatGPT 组织 ID |
| `id_token` | 可选 | - |
| `refresh_token` | 可选 | - |
| `last_refresh` | 可选 | - |

## 构建

```bash
cd CliproxyAPIStats
swift build
swift run
```

## License

MIT
