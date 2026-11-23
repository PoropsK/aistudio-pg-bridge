# Unraid Docker WebGUI 部署

這份流程直接使用 Unraid 的 **Docker → Add Container**。不需要加入 GitHub Template Repository，也不需要在 Unraid 執行指令。XML 檔只是可選的預填表單，直接手動輸入的結果相同。

## 1. 先確認映像檔

GHCR image：

```text
ghcr.io/poropsk/aistudio-pg-bridge:latest
```

目前發布 `linux/amd64` 與 `linux/arm64`，Unraid 會依主機架構拉取對應 image。GHCR package 必須維持 Public。

## 2. 直接 Add Container

在 Unraid WebGUI 開啟 **Docker → Add Container**，填入以下欄位。

### 基本設定

| WebGUI 欄位 | 值 |
|---|---|
| Name | `AI Studio PG Bridge` |
| Repository | `ghcr.io/poropsk/aistudio-pg-bridge:latest` |
| Network Type | `bridge` |
| Privileged | 關閉 |
| Extra Parameters | `--init` |

### Port

新增一個 TCP Port：

| Host port | Container port | Protocol |
|---:|---:|---|
| `18802` | `18802` | TCP |

只新增 `18802`。Proof Server 的 `18801` 留在容器內，不要建立 Host Port mapping。

### Path

新增兩個 Read/Write Path：

| Host path | Container path | Mode |
|---|---|---|
| `/mnt/user/appdata/aistudio-pg-bridge/cookies` | `/app/2-relay-client-gateway/cookies` | Read/Write |
| `/mnt/user/appdata/aistudio-pg-bridge/data` | `/app/3-waa-proof-server/data` | Read/Write |

Unraid 會在 Apply 時建立或使用這些 appdata 目錄。Cookie 目錄包含登入憑證，請限制存取權限並納入私有備份。

### Environment Variables

在 WebGUI 的 Environment Variables 區域逐項新增：

| Name | Value | Advanced |
|---|---|---|
| `RELAY_HOST` | `0.0.0.0` | 否 |
| `RELAY_PORT` | `18802` | 是 |
| `RELAY_API_KEY` | 自訂長隨機字串 | 否，Mask |
| `DEFAULT_MODEL` | `gemini-3.8-flash` | 否 |
| `COOKIES_DIR` | `./cookies` | 是 |
| `AUTO_START_PROOF` | `1` | 是 |
| `PROOF_HOST` | `127.0.0.1` | 是 |
| `PROOF_PORT` | `18801` | 是 |
| `MINT_LEDGER_FILE` | `/app/3-waa-proof-server/data/mint-ledger.log` | 是 |

`RELAY_API_KEY` 同時用於面板登入與 API 的 Bearer Token。不要使用預設值，也不要把它提交到 Git。

按 **Apply** 後，Unraid 會從 GHCR 拉取 image、建立容器並保存設定。容器啟動時，Relay 會在同一個容器內自動啟動 Proof Server。

## 3. 第一次檢查

在瀏覽器開啟：

```text
http://<Unraid-IP>:18802/
```

輸入 `RELAY_API_KEY` 登入面板，再匯入自己的 AI Studio Cookie。Docker WebGUI 的容器圖示應顯示 Healthy，因為 image 內建 `/health` healthcheck。

## 4. Caddy

### Caddy 在 Unraid host 或 host network

```caddyfile
ai.example.com {
    encode gzip
    reverse_proxy 127.0.0.1:18802 {
        flush_interval -1
    }
}
```

### Caddy 是另一個 Docker container

將 upstream 改成 Unraid LAN IP：

```caddyfile
ai.example.com {
    encode gzip
    reverse_proxy 192.168.1.10:18802 {
        flush_interval -1
    }
}
```

也可以將 Caddy 與 Relay 放在同一個 Docker network，使用 `aistudio-pg-bridge:18802`。不要在 Caddy container 內使用自己的 `127.0.0.1`。

## 5. 日後更新

1. GitHub fork 使用 **Sync fork**，或推送你審核過的程式更新。
2. GitHub Actions 成功發布新的 `latest` digest。
3. 在 Unraid **Docker** 頁面檢查更新，對 AI Studio PG Bridge 按 **Update**。
4. Unraid 會保留本次 Add Container 的 Port、Path、Variable 設定並重新建立容器。

如果暫時不想跟隨 `latest`，可以在 WebGUI 的 Repository 改成 `ghcr.io/poropsk/aistudio-pg-bridge:sha-<commit>`，驗證後再切回 `latest`。

## 6. XML Template 的位置

`templates/aistudio-pg-bridge.xml` 可以讓 Unraid 預填上述欄位。使用它需要把 GitHub repository 加入 Docker Repositories。這是捷徑，不是必要依賴。直接 Add Container 手動輸入時，容器啟動與更新方式相同。
