FROM golang:1.22-alpine as builder

RUN set -ex \
    && go version  \
    && wget https://github.com/TwiN/gatus/archive/refs/tags/v5.8.0.tar.gz -O /tmp/gatus.tgz \
    && mkdir -p /app \
    && tar xzfv /tmp/gatus.tgz -C /app --strip-components=1

WORKDIR /app
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .

# NB: 2024.03.16 skipping TestPing due to tests failure while running in docker due to
# v 5.8.0: https://github.com/TwiN/gatus/blob/5aa83ee274e92f37a771d0e9cb797ef36f13e176/client/client_test.go#L94-L99
RUN apk update && apk add --virtual build-dependencies build-base gcc \
    && go test ./... -race -skip TestPing

FROM scratch

COPY --from=builder /app/gatus .
COPY --from=builder /app/config.yaml ./config/config.yaml
COPY --from=builder /app/web/static ./web/static
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

EXPOSE 8080

ENTRYPOINT [ "/gatus" ]
