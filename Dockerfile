FROM golang:1.22-alpine AS builder

LABEL maintainer="vivino.com"

ENV CGO_ENABLED=0
ENV GO111MODULE=on
ENV GOPROXY=https://proxy.golang.org

WORKDIR /app

# Copy go.mod and go.sum to leverage Docker cache for dependencies
COPY go.mod go.sum ./

# Install git and download dependencies
RUN apk add --no-cache git && \
    go mod download

# Copy the rest of the source code
COPY . .

# Build the applications
RUN go build -v -o /go/bin/rankdb ./cmd/rankdb && \
    go build -v -o /go/bin/rankdb-cli ./api/tool/rankdb-cli

FROM alpine:3.10

EXPOSE 8080

# Copy the built binaries from the builder stage
COPY --from=builder /go/bin/rankdb /usr/bin/rankdb
COPY --from=builder /go/bin/rankdb-cli /usr/bin/rankdb-cli

# Copy necessary files
COPY api/public /api/public
COPY api/swagger /api/swagger
COPY conf/conf.stub.toml /conf/conf.toml
COPY cmd/docker-entrypoint.sh /usr/bin/

VOLUME ["/data", "/conf", "/jwtkeys"]

HEALTHCHECK --interval=1m CMD rankdb-cli --timeout=1s health health

WORKDIR /

CMD ["rankdb"]