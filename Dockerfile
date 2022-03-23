FROM golang:1.17-alpine as builder

ADD https://github.com/TwiN/gatus/archive/refs/tags/v3.7.0.tar.gz /gatus.tgz

RUN set -ex \
    && apk --update add ca-certificates \
    && mkdir -p /app \
    && tar xzfv /gatus.tgz -C /app --strip-components=1 \
    && go version \
    && ls -la /etc/ssl/certs/ca-certificates.crt \
    && wget -q -P /usr/local/share/ca-certificates/ \
        https://letsencrypt.org/certs/isrgrootx1.pem \
        https://letsencrypt.org/certs/isrg-root-x2.pem \
        https://letsencrypt.org/certs/lets-encrypt-r3.pem \
        https://letsencrypt.org/certs/lets-encrypt-e1.pem \
        https://letsencrypt.org/certs/lets-encrypt-r4.pem \
        https://letsencrypt.org/certs/lets-encrypt-e2.pem \
    && update-ca-certificates \
    && ls -la /etc/ssl/certs/ca-certificates.crt

# certificates from https://letsencrypt.org/certificates/

WORKDIR /app

RUN CGO_ENABLED=0 GOOS=linux go build -mod vendor -a -installsuffix cgo -o gatus .

RUN apk update && apk add --virtual build-dependencies build-base gcc

RUN go test -mod vendor ./... -race


FROM scratch

COPY --from=builder /app/gatus .
COPY --from=builder /app/config.yaml ./config/config.yaml
COPY --from=builder /app/web/static ./web/static
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

EXPOSE 8080

ENTRYPOINT [ "/gatus" ]
