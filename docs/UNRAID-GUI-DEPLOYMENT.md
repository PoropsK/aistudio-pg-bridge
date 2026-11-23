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

## 7. XML Template 詳細使用教學

### 7.1 XML 在這裡做什麼

XML Template 是 Unraid Docker WebGUI 的表單描述檔。它會預先填入：

- Docker image Repository
- Registry
- Network Type
- WebUI 連結
- Host Port 和 Container Port
- Host Path 和 Container Path
- Environment Variables
- Extra Parameters

按 Apply 之後，Unraid 仍然建立一般 Docker container，並把最後使用的設定保存到自己的 Docker template。日後你可以在 Docker 頁面按容器圖示，再使用 Edit、Logs、Restart、Update。

### 7.2 使用 GitHub Template Repository 加入 XML

這是最方便的 XML 使用方式：

1. 登入 Unraid WebGUI。
2. 開啟 **Apps**。
3. 找到 **Docker Repositories** 或 Template repositories 設定。
4. 新增：

   ```text
   https://github.com/PoropsK/aistudio-pg-bridge
   ```

5. 儲存並重新整理。
6. 開啟 **Docker → Add Container**。
7. 在 Template 下拉選單選擇 **AI Studio PG Bridge**。

Unraid 會從 repository 的 `templates/aistudio-pg-bridge.xml` 載入預填欄位。Template 內的 image 已經指向：

```text
ghcr.io/poropsk/aistudio-pg-bridge:latest
```

### 7.3 套用前要檢查的欄位

開啟 Template 後，建議切換 **Advanced View**，逐項確認：

| 欄位 | 應有的值 | 用途 |
|---|---|---|
| Repository | `ghcr.io/poropsk/aistudio-pg-bridge:latest` | 要拉取的容器 image |
| Network Type | `bridge` | 一般 Docker bridge 網路 |
| Relay Web/API port | Host `18802` → Container `18802`, TCP | 面板、OpenAI API、Gemini API |
| Cookie data | `/mnt/user/appdata/aistudio-pg-bridge/cookies` → `/app/2-relay-client-gateway/cookies` | 保存 Cookie 帳號檔 |
| Mint ledger data | `/mnt/user/appdata/aistudio-pg-bridge/data` → `/app/3-waa-proof-server/data` | 保存 mint ledger |
| Relay host | `0.0.0.0` | 允許 Docker port mapping 連入 |
| Relay API key | 自己產生的值 | 面板登入和 API 驗證 |
| Default model | `gemini-3.8-flash` | 沒指定 model 時使用 |
| Auto start proof server | `1` | 啟動 Relay 時一併啟動 Proof Server |
| Proof host | `127.0.0.1` | 讓 Proof Server 只留在容器內 |
| Proof port | `18801` | 內部連接埠，不要新增 Host Port |
| Extra Parameters | `--init` | 讓容器使用 init process 管理子程序 |

Cookie Path 與 Mint ledger Path 需要使用 Unraid 的 `/mnt/user/appdata`，不要把它們留在容器內的匿名層。這樣更新 image 或刪除重建 container 時，資料仍然保留。

### 7.4 用 Unraid Web Command Line 產生 RELAY_API_KEY

在 Unraid WebGUI 開啟 Terminal，或使用 Unraid 的 Web Command Line，執行：

```bash
openssl rand -hex 32
```

畫面會輸出一組 64 字元的十六進位字串，例如：

```text
f1e2d3c4b5a697887766554433221100aabbccddeeff00112233445566778899
```

使用你實際產生的值，不要使用上面的示例。複製輸出後，貼到 Template 的 **Relay API key** 欄位。這個值只需要放在 Unraid 的容器設定中，不需要寫入 Dockerfile、GitHub repository 或 Caddyfile。

如果想讓 command history 不包含變數名稱以外的內容，可以使用：

```bash
KEY="$(openssl rand -hex 32)"; printf '%s\n' "$KEY"
```

Terminal 會顯示產生的值，複製它後再清除或關閉該 Terminal 視窗。不要把 API Key 貼到聊天、Issue、截圖或公開日誌。

### 7.5 按 Apply 後怎麼確認

1. 按 **Apply**。
2. 等待 Unraid 拉取 image 並建立 container。
3. 在 Docker 頁面確認容器狀態為 Started 或 Healthy。
4. 點容器圖示，開啟 **Logs**。
5. 看到以下類似訊息代表兩個程序都已啟動：

   ```text
   [WAA Proof Server] Listening on http://127.0.0.1:18801
   [Relay Gateway] Dashboard: http://0.0.0.0:18802/
   [Relay Gateway] OpenAI Base: http://0.0.0.0:18802/v1
   ```

6. 按 WebUI，或直接開啟 `http://<Unraid-IP>:18802/`。
7. 使用 `RELAY_API_KEY` 登入面板。
8. 匯入自己的 AI Studio Cookie。

### 7.6 XML 更新和 image 更新的差別

- **image 更新**：GitHub Actions 發布新的 `latest` digest，Unraid Docker 更新檢查會發現新 image，按 Update 即可。
- **XML 更新**：Template repository 的 XML 欄位有變更時，先重新整理 Template Repository，再在 Add Container 或 Edit 頁面載入新欄位。
- **既有容器設定**：Unraid 會使用你最後按 Apply 保存的設定。更新 image 不會覆蓋 appdata Path，也不會重新產生 API Key。

### 7.7 回復舊 image

如果最新 image 發生問題，在 Docker WebGUI 編輯容器，把 Repository 暫時改成固定 tag，例如：

```text
ghcr.io/poropsk/aistudio-pg-bridge:sha-72b2237
```

按 Apply 後，Unraid 會用該版本重新建立容器。確認問題排除後，再改回：

```text
ghcr.io/poropsk/aistudio-pg-bridge:latest
```
