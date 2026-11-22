# OmniPulse Microservice Application Dockerfile (Build context: ./src)
ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM golang:1.27.0-alpine@sha256:4c9fe60190a2a3350ddc51de80d0224b8a6698d12bdfc999fee45ea9d6c46dbc AS builder
ARG TARGETOS=linux
ARG TARGETARCH=amd64
WORKDIR /src

COPY frontend/go.mod frontend/go.sum ./
RUN go mod download
COPY frontend/ .

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} CGO_ENABLED=0 go build -ldflags="-s -w" -o /go/bin/frontend .

FROM gcr.io/distroless/static
WORKDIR /src
COPY --from=builder /go/bin/frontend /src/server
COPY frontend/templates ./templates
COPY frontend/static ./static

ENV GOTRACEBACK=single
EXPOSE 8080
ENTRYPOINT ["/src/server"]

