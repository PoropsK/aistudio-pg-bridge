# Unraid Docker WebGUI 部署

## 一次性設定

1. 確認 GitHub Actions 已成功發布 `ghcr.io/PoropsK/aistudio-pg-bridge:latest`。
2. 將 GHCR package 設為 Public。
3. 在 Unraid Docker Repositories 加入：

   `https://github.com/PoropsK/aistudio-pg-bridge`

GitHub Actions 會發布 `linux/amd64` 與 `linux/arm64` 兩個架構，Unraid 會依主機架構自動拉取對應 image。

4. 在 Docker → Add Container 選擇 **AI Studio PG Bridge**。
5. 設定 `Relay API key`，並確認兩個路徑：

   - `/mnt/user/appdata/aistudio-pg-bridge/cookies` → `/app/2-relay-client-gateway/cookies`
   - `/mnt/user/appdata/aistudio-pg-bridge/data` → `/app/3-waa-proof-server/data`

6. 按 Apply。只使用 `18802`，不要發布 Proof Server 的 `18801`。

## Caddy

```caddyfile
ai.example.com {
    encode gzip
    reverse_proxy 127.0.0.1:18802 {
        flush_interval -1
    }
}
```

如果 Caddy 是另一個 Docker container，將 upstream 改成 Unraid LAN IP 的 `18802`，或使用同一個 Docker network 的容器名稱。

## 更新

1. 在 GitHub fork 使用 **Sync fork** 更新上游程式碼。
2. 等待 **Build and publish Unraid image** 成功。
3. 在 Unraid Apps → Action Center 按 **Update**。

容器設定和 Cookie 位於 Unraid Template 與 appdata，更新 image 不會刪除它們。
