# syntax=docker/dockerfile:1
# Image of fnmctl. Build from the repository root:
#   docker build -f deploy/fnm/fnmctl/Dockerfile -t fnm/fnmctl .
# Base images are pinned by digest; Dependabot proposes updates.

FROM golang:1.26.11-bookworm@sha256:dc40a13b61304647ed7e5d581d246b86413dfc29d63c6d018310feb93cd98fc0 AS build
ENV CGO_ENABLED=0 GOTOOLCHAIN=local GOFLAGS=-mod=readonly
WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download && go mod verify
COPY cmd/ cmd/
COPY internal/ internal/
RUN go build -trimpath -buildvcs=false -ldflags="-s -w -buildid=" -o /out/fnmctl ./cmd/fnmctl

FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
COPY --from=build /out/fnmctl /usr/local/bin/fnmctl
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/fnmctl"]
