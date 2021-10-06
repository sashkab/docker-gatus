FROM golang:alpine as builder

ADD https://github.com/TwinProduction/gatus/archive/refs/tags/v3.2.1.tar.gz /gatus.tgz

RUN set -ex \
    && apk --update add ca-certificates \
    && mkdir -p /app \
    && tar xzfv /gatus.tgz -C /app --strip-components=1

WORKDIR /app

RUN CGO_ENABLED=0 GOOS=linux go build -mod vendor -a -installsuffix cgo -o gatus .

RUN apk update && apk add --virtual build-dependencies build-base gcc sudo

# We're using "sudo" because one of the tests leverages ping, which requires super-user privileges.
# As for the 'env "PATH=$PATH" "GOROOT=$GOROOT"', we need it to use the same "go" executable that
# was configured by the "Set up Go 1.15" step (otherwise, it'd use sudo's "go" executable)
# Lifted from https://github.com/TwinProduction/gatus/blob/v3.2.1/.github/workflows/build.yml#L25
RUN sudo env "PATH=$PATH" "GOROOT=$GOROOT" go test -mod vendor ./... -race


FROM scratch

COPY --from=builder /app/gatus .
COPY --from=builder /app/config.yaml ./config/config.yaml
COPY --from=builder /app/web/static ./web/static
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

EXPOSE 8080

ENTRYPOINT [ "/gatus" ]
