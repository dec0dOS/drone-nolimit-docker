# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM golang:alpine as build

RUN apk add -U --no-cache ca-certificates git build-base
ARG DRONE_VERSION
RUN mkdir -p /src/drone && \
    cd /src/drone && \
    git clone --depth 1 --branch "${DRONE_VERSION}" https://github.com/harness/gitness .
ARG TARGETOS TARGETARCH
RUN cd /src/drone/cmd/drone-server && GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_CFLAGS="-D_LARGEFILE64_SOURCE" go build -tags "nolimit" -ldflags "-extldflags \"-static\"" -o drone-server

FROM alpine:latest

EXPOSE 80 443
VOLUME /data

RUN echo 'hosts: files dns' > /etc/nsswitch.conf 

ARG TARGETARCH

ENV GODEBUG netdns=go
ENV XDG_CACHE_HOME /data
ENV DRONE_DATABASE_DRIVER sqlite3
ENV DRONE_DATABASE_DATASOURCE /data/database.sqlite
ENV DRONE_RUNNER_OS=linux
ENV DRONE_RUNNER_ARCH=$TARGETARCH
ENV DRONE_SERVER_PORT=:80
ENV DRONE_SERVER_HOST=localhost
ENV DRONE_DATADOG_ENABLED=false

COPY --from=build /src/drone/cmd/drone-server/drone-server /bin/
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

ENTRYPOINT ["/bin/drone-server"]
