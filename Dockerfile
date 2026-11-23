FROM node:22-bookworm-slim

ENV NODE_ENV=production \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false

WORKDIR /app

# Relay 會用相鄰路徑自動啟動 Proof Server，兩個目錄必須保留原本的層級。
COPY 2-relay-client-gateway /app/2-relay-client-gateway
COPY 3-waa-proof-server /app/3-waa-proof-server

RUN mkdir -p /app/2-relay-client-gateway/cookies /app/3-waa-proof-server/data \
    && chmod 700 /app/2-relay-client-gateway/cookies /app/3-waa-proof-server/data \
    && chmod +x /app/2-relay-client-gateway/bin/start-relay.js \
    /app/3-waa-proof-server/bin/start-proof-server.js

WORKDIR /app/2-relay-client-gateway

EXPOSE 18802

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:18802/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

CMD ["node", "bin/start-relay.js"]

