#!/bin/bash

set -eux -o pipefail

cd "$(dirname "$0")"

GOOS=linux GOARCH=amd64 ocb --config=distributions/otelcol-contrib/manifest.yaml

cd _build
cp -r ../distributions/otelcol-contrib/* .
docker buildx build --platform=linux/amd64 -t otelcol-contrib-hasegawa .

docker tag otelcol-contrib-hasegawa hasegawapowerxjp/otelcol-contrib:latest
docker push hasegawapowerxjp/otelcol-contrib:latest

kubectx adam-dev
kubectl -n otel-system rollout restart deployment remote-collector