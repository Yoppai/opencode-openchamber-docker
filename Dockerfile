# syntax=docker/dockerfile:1
# build-container-image — ch-02
# Single-stage: node:22-bookworm-slim + OpenCode + OpenChamber + Bun + tooling
# Tradeoff: ~50-100MB extra vs multi-stage; avoids native-module breakage (better-sqlite3, node-pty, bun-pty)

ARG OPENCODE_VERSION=latest
ARG OPENCHAMBER_VERSION=latest
ARG GENTLE_AI_VERSION=1.25.6
ARG ENGRAM_VERSION=1.15.8

FROM node:22-bookworm-slim

ARG OPENCODE_VERSION
ARG OPENCHAMBER_VERSION
ARG GENTLE_AI_VERSION
ARG ENGRAM_VERSION

# TARGETARCH inyectado por Buildx: linux/amd64 → "x64-baseline", linux/arm64 → "aarch64"
ARG TARGETARCH

# 1.3: OS deps + clean apt cache
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        gh \
        jq \
        openssh-client \
        tini \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# 1.4: Bun release tarball
RUN case "${TARGETARCH}" in \
        amd64|x86_64)   BUN_ARCH="x64-baseline" ;; \
        arm64|aarch64)  BUN_ARCH="aarch64" ;; \
        *)              echo "Unsupported TARGETARCH: ${TARGETARCH}"; exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/oven-sh/bun/releases/latest/download/bun-linux-${BUN_ARCH}.zip" -o /tmp/bun.zip && \
    unzip -o /tmp/bun.zip -d /usr/local/bin/ && \
    mv /usr/local/bin/bun-linux-${BUN_ARCH}/bun /usr/local/bin/bun && \
    rm -rf /tmp/bun.zip /usr/local/bin/bun-linux-${BUN_ARCH} && \
    chmod +x /usr/local/bin/bun

# 1.5: OpenCode global before OpenChamber
RUN npm install -g "opencode-ai@${OPENCODE_VERSION}" && \
    npm cache clean --force

# 1.6: OpenChamber global + clean npm cache
RUN npm install -g "@openchamber/web@${OPENCHAMBER_VERSION}" && \
    npm cache clean --force

# 1.6b: Gentle-AI binary from GitHub Releases (multi-arch)
RUN case "${TARGETARCH}" in \
        amd64|x86_64)   GA_ARCH="amd64" ;; \
        arm64|aarch64)  GA_ARCH="arm64" ;; \
        *)              echo "Unsupported TARGETARCH: ${TARGETARCH}"; exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/Gentleman-Programming/gentle-ai/releases/download/v${GENTLE_AI_VERSION}/gentle-ai_${GENTLE_AI_VERSION}_linux_${GA_ARCH}.tar.gz" \
        -o /tmp/gentle-ai.tar.gz && \
    tar -xzf /tmp/gentle-ai.tar.gz -C /usr/local/bin/ gentle-ai && \
    chmod +x /usr/local/bin/gentle-ai && \
    rm /tmp/gentle-ai.tar.gz && \
    echo "Gentle-AI $(gentle-ai version) installed"

# 1.6c: Engram binary from GitHub Releases (multi-arch)
# Gentle-AI can configure Engram, but OpenCode MCP needs `engram` on PATH.
RUN case "${TARGETARCH}" in \
        amd64|x86_64)   ENGRAM_ARCH="amd64" ;; \
        arm64|aarch64)  ENGRAM_ARCH="arm64" ;; \
        *)              echo "Unsupported TARGETARCH: ${TARGETARCH}"; exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/Gentleman-Programming/engram/releases/download/v${ENGRAM_VERSION}/engram_${ENGRAM_VERSION}_linux_${ENGRAM_ARCH}.tar.gz" \
        -o /tmp/engram.tar.gz && \
    tar -xzf /tmp/engram.tar.gz -C /usr/local/bin/ engram && \
    chmod +x /usr/local/bin/engram && \
    rm /tmp/engram.tar.gz && \
    echo "Engram $(engram version) installed"

# 1.7: Create non-root user (rename existing node:node UID/GID 1000 to openchamber)
RUN groupmod -n openchamber node && \
    usermod -l openchamber -d /home/openchamber -m node

# 1.8: Defensive env for openchamber opencode resolution
ENV OPENCODE_BINARY=/usr/local/bin/opencode

# 1.7 (cont): WORKDIR + USER
WORKDIR /home/openchamber

# 1.8: Copy entrypoint script before switching user
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER openchamber

# 1.8b: Default opencode config with opencode-synced plugin
# Volume mounts may override; entrypoint ensures plugin persists.
RUN mkdir -p /home/openchamber/.config/opencode /home/openchamber/workspaces && \
    printf '{\n  "$schema": "https://opencode.ai/config.json",\n  "plugin": ["opencode-synced"]\n}\n' \
    > /home/openchamber/.config/opencode/opencode.json

# 1.9: tini entrypoint + entrypoint script
ENTRYPOINT ["tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD []
