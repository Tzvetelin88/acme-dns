FROM golang:alpine AS builder
LABEL maintainer="joona@kuori.org"

RUN apk add --update git

ENV GOPATH /tmp/buildcache
COPY . /tmp/acme-dns
WORKDIR /tmp/acme-dns
RUN CGO_ENABLED=0 go build -ldflags="-s -w"

FROM alpine:latest

# Create nonroot user matching the deployment securityContext (uid/gid 65532)
RUN addgroup -g 65532 -S nonroot && adduser -u 65532 -S nonroot -G nonroot

WORKDIR /app
COPY --from=builder /tmp/acme-dns/acme-dns /app/acme-dns
RUN mkdir -p /etc/acme-dns /var/lib/acme-dns && \
    chown -R nonroot:nonroot /etc/acme-dns /var/lib/acme-dns && \
    apk --no-cache add ca-certificates && update-ca-certificates

USER nonroot

VOLUME ["/etc/acme-dns", "/var/lib/acme-dns"]
ENTRYPOINT ["/app/acme-dns"]
EXPOSE 53 80 443
EXPOSE 53/udp
