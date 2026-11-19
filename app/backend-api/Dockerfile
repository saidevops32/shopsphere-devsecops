# syntax=docker/dockerfile:1
# --- Stage 1: install prod deps (build tools never reach the runtime image) ---
FROM node:20.18-alpine3.20 AS deps
WORKDIR /app
COPY package.json ./
# Layer caching: this layer only rebuilds when package.json changes
RUN npm install --omit=dev --ignore-scripts && npm cache clean --force

# --- Stage 2: distroless runtime (no shell, no package manager, tiny attack surface) ---
FROM gcr.io/distroless/nodejs20-debian12:nonroot
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY src ./src
COPY package.json ./
USER 10001
EXPOSE 3000
# No HEALTHCHECK: Kubernetes probes own health (distroless has no curl/wget)
CMD ["src/server.js"]
