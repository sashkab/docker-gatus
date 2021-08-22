FROM golang:alpine as builder

ADD https://github.com/TwinProduction/gatus/archive/refs/tags/v2.9.0.tar.gz /gatus.tgz

RUN set -ex \
    && apk --update add ca-certificates \
    && mkdir -p /app \
    && tar xzfv /gatus.tgz -C /app --strip-components=1

WORKDIR /app

RUN CGO_ENABLED=0 GOOS=linux go build -mod vendor -a -installsuffix cgo -o gatus .

RUN apk update && apk add --virtual build-dependencies build-base gcc
RUN go test ./... -mod vendor


FROM scratch

COPY --from=builder /app/gatus .
COPY --from=builder /app/config.yaml ./config/config.yaml
COPY --from=builder /app/web/static ./web/static
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

EXPOSE 8080

ENTRYPOINT [ "/gatus" ]
