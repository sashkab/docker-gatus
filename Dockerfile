FROM golang:1.21-alpine as builder

RUN set -ex \
    && go version  \
    && wget https://github.com/TwiN/gatus/archive/refs/tags/v5.6.0.tar.gz -O /tmp/gatus.tgz \
    && mkdir -p /app \
    && tar xzfv /tmp/gatus.tgz -C /app --strip-components=1

WORKDIR /app
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .

RUN apk update && apk add --virtual build-dependencies build-base gcc \
    && go test ./... -race

FROM scratch

COPY --from=builder /app/gatus .
COPY --from=builder /app/config.yaml ./config/config.yaml
COPY --from=builder /app/web/static ./web/static
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

EXPOSE 8080

ENTRYPOINT [ "/gatus" ]
