# OpenTelemetry Collector Contrib Customized by Hasegawa

Basically printf debugging and customized metrics exports.

## How to deploy

### Build the locally-modified OpenTelemetry Collector binary

First install the
[OpenTelemetry Collector Builder](https://github.com/open-telemetry/opentelemetry-collector/tree/main/cmd/builder).
I recommend to install by putting the official release binary in your PATH.
The latest version as of writing is
[v0.116.0](https://github.com/open-telemetry/opentelemetry-collector-releases/releases/tag/cmd%2Fbuilder%2Fv0.116.0).

Then run this command at the root of this repository. Note that the binary should be built for Alpine Linux x86_64.
(That's what we use in the `Dockerfile`.)

```shell
GOOS=linux GOARCH=amd64 ocb --config=distributions/otelcol-contrib/manifest.yaml
```

The binary is output to `./_build/otelcol-contrib`.

Note: this `manifejst.yaml` is a copy of the
[official manifest](https://github.com/open-telemetry/opentelemetry-collector-releases/blob/main/distributions/otelcol-contrib/manifest.yaml)
with a tweak to use some code from this repository.

### Test building the Docker image

To test out the Docker container locally, run the following to build the Docker image named `otelcol-contrib-hasegawa`.

```shell
cd _build
cp -r ../distributions/otelcol-contrib/* .
docker buildx build --platform=linux/amd64 -t otelcol-contrib-hasegawa .
```

`docker buildx build --platform=linux/amd64` instead of `docker build` is especially needed when you build on a Mac
machine. See https://gist.github.com/yamaneko1212/11f1a8747a4def51d0a2ca0580a7bebc.

Test by running it:

```shell
docker run otelcol-contrib-hasegawa
```

It should output `Everything is ready. Begin running and processing data.` and then start processing and something like

```text
Metric #17
Descriptor:
     -> Name: scrape_series_added
     -> Description: The approximate number of new series in this scrape
     -> Unit: 
     -> DataType: Gauge
NumberDataPoints #0
StartTimestamp: 1970-01-01 00:00:00 +0000 UTC
Timestamp: 2024-12-19 13:35:08.732 +0000 UTC
Value: 38.000000
        {"kind": "exporter", "data_type": "metrics", "name": "debug"}
```

Then this container image should be ready for deploy.

### Push to Docker Hub

Tag the local image with the repository name and push it. Here the registry name is omitted and it defaults to the
Docker Hub.

```shell
docker tag otelcol-contrib-hasegawa hasegawapowerxjp/otelcol-contrib:latest
docker push hasegawapowerxjp/otelcol-contrib:latest
```

### Push to Artifact Registry

NOTE: This is currently not supported due to the lack of auth token in Adam.

Follow https://cloud.google.com/artifact-registry/docs/docker/pushing-and-pulling.

Tag the local image with the repository name and push it.

```shell
docker tag otelcol-contrib-hasegawa asia-northeast1-docker.pkg.dev/powerx-jp/cr/otelcol-contrib-hasegawa:latest
docker push asia-northeast1-docker.pkg.dev/powerx-jp/cr/otelcol-contrib-hasegawa:latest
```

### Deploy with ArgoCD

Make a change in https://github.com/powerx-jp/powerx/blob/main/manifests/otel-system/k0s-base/kustomization.yaml so that
`collectorImage` points to the new image.

- If you pushed to Docker Hub:
  ```yaml
  collectorImage:
    repository: "hasegawapowerxjp/otelcol-contrib"
    tag: "latest" 
  ```
- If you pushed to Artifact Registry:
  ```yaml
  collectorImage:
    repository: "asia-northeast1-docker.pkg.dev/powerx-jp/cr/otelcol-contrib-hasegawa"
    tag: "latest" 
  ```

Push the branch and sync `otel-system-k0s-develop` application to it.

ArgoCD is typically slow to detect a new image comes. To quicken the process, you can delete the replica set of the pod
in question, or alternatively you can roll out the deployment:

```shell
kubectx adam-dev
kubectl -n otel-system rollout restart deployment remote-collector
```

There is a shell script to automate these steps using Docker
Hub: [deploy_otelcol_contrib.sh](deploy_otelcol_contrib.sh).