FROM golang:1.23-alpine as builder

RUN set -ex \
    && go version  \
    && wget https://github.com/TwiN/gatus/archive/refs/tags/v5.14.0.tar.gz -O /tmp/gatus.tgz \
    && mkdir -p /app \
    && tar xzfv /tmp/gatus.tgz -C /app --strip-components=1 \
    && apk --no-cache add patch \
    && wget https://github.com/TwiN/gatus/commit/69dbe4fa2318eb2f6a422a308a3be9642cdcfca0.patch -O /tmp/69dbe4fa.patch \
    && patch -d /app -p1 < /tmp/69dbe4fa.patch

# NB: temporary workaround to fix flaky DNS tests 2025.01.19

WORKDIR /app
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .

RUN apk update && apk add --virtual build-dependencies build-base gcc sudo \
    && sudo env "PATH=$PATH" "GOROOT=$GOROOT" go test ./... -race

FROM scratch

COPY --from=builder /app/gatus .
COPY --from=builder /app/config.yaml ./config/config.yaml
COPY --from=builder /app/web/static ./web/static
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

EXPOSE 8080

ENTRYPOINT [ "/gatus" ]
