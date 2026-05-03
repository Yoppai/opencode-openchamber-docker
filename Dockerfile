# syntax=docker/dockerfile:1
# build-container-image — ch-02
# Single-stage: node:22-bookworm-slim + OpenCode + OpenChamber + Bun + tooling
# Tradeoff: ~50-100MB extra vs multi-stage; avoids native-module breakage (better-sqlite3, node-pty, bun-pty)

ARG OPENCODE_VERSION=latest
ARG OPENCHAMBER_VERSION=latest

FROM node:22-bookworm-slim

ARG OPENCODE_VERSION
ARG OPENCHAMBER_VERSION

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

# 1.7: Create non-root user (rename existing node:node UID/GID 1000 to openchamber)
RUN groupmod -n openchamber node && \
    usermod -l openchamber -d /home/openchamber -m node

# 1.8: Defensive env for openchamber opencode resolution
ENV OPENCODE_BINARY=/usr/local/bin/opencode

# 1.7 (cont): WORKDIR + USER
WORKDIR /home/openchamber
USER openchamber

# 1.9: tini entrypoint + default bash
ENTRYPOINT ["tini", "--"]
CMD ["bash"]
