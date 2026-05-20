FROM golang:1.26-alpine AS builder

RUN set -ex \
    && apk update && apk add --no-cache wget \
    && go version  \
    && wget -v https://github.com/TwiN/gatus/archive/refs/tags/v5.36.0.tar.gz -O /tmp/gatus.tgz \
    && mkdir -p /app \
    && tar xzfv /tmp/gatus.tgz -C /app --strip-components=1

WORKDIR /app
RUN go mod tidy -diff
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .

# RUN apk update && apk add --virtual build-dependencies build-base gcc sudo \
#     && sudo env "PATH=$PATH" "GOROOT=$GOROOT" go test ./... -race

FROM scratch

COPY --from=builder /app/gatus .
COPY --from=builder /app/config.yaml ./config/config.yaml
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

EXPOSE 8080

ENTRYPOINT [ "/gatus" ]
