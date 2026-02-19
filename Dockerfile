FROM docker:27-cli AS dockercli

FROM node:20-bookworm-slim AS build

WORKDIR /opt/cronicle

COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts

COPY . .
RUN node bin/build.js dist

FROM node:20-bookworm-slim

ENV NODE_ENV=production

WORKDIR /opt/cronicle

RUN apt-get update && apt-get install -y --no-install-recommends procps curl && rm -rf /var/lib/apt/lists/*

COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker

RUN useradd --system --create-home --home-dir /opt/cronicle --shell /usr/sbin/nologin cronicle

COPY --from=build --chown=cronicle:cronicle /opt/cronicle /opt/cronicle

RUN mkdir -p data logs queue && chown -R cronicle:cronicle /opt/cronicle

EXPOSE 3012 3014/udp

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD ["curl", "-fsS", "http://127.0.0.1:3012/api/app/status"]

USER cronicle

CMD ["node", "lib/main.js", "--debug", "--echo"]
