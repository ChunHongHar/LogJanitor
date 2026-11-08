# LogJanitor

A small utility container to perform automatic logs rotation for any service.

## How to run as standalone container

```sh
# To build the container
sh build.sh

docker run \
  -v /var/lib/docker/containers:/var/log/containers \
  -e LOGROTATE_LOGFILES="/var/log/containers/*.log /var/log/containers/*/*.log" \
  ChunHongHar/LogJanitor
```

## Customisation

### Set a cron schedule

You can set a different cron schedule from the default (once every 24 hours), by setting the environment variable `LOGROTATE_CRON_EXPR` before starting the container.

```sh
docker run \
  -v /var/lib/docker/containers:/var/log/containers \
  -e LOGROTATE_LOGFILES="/var/log/containers/*.log" \
  -e LOGROTATE_CRON_EXPR="0 0-23/12 * * *" # Rotate every 12 hours
  ChunHongHar/LogJanitor
```

### Change location of logfiles to monitor for

Update `LOGROTATE_LOGFILES` environment variable to change which logfiles are managed by LogJanitor.

```sh
docker run \
  -v /var/lib/docker/containers:/customlogs \
  -e LOGROTATE_LOGFILES="/customlogs/*.log /customlogs/*/*.log" \
  ChunHongHar/LogJanitor
```

## How to run as Kubernetes Sidecar

As this is a standalone container, it is runnable as a Kubernetes sidecar container to any pod. Make sure that logs are mounted as a volume to the `logjanitor` container so LogJanitor can "see" them.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
  namespace: default
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: my-service
        app.kubernetes.io/instance: my-service
        app.kubernetes.io/version: 0.1
    spec:
      containers:
        - name: my-service
          image: my-org/my-service:0.1
          resources:
            requests:
              cpu: 1
              memory: 1Gi
          volumeMounts:
            - mountPath: /var/log  # my-service writes logs into /var/log
              name: app-logs
        # Sidecar containers
        - name: logjanitor
          image: ChunHongHar/LogJanitor:0.1
          resources:
            requests:
              cpu: 0.1
              memory: 100Mi
          env:
            # LogJanitor configuration environment variables
            - name: LOGROTATE_LOGFILES
              value: "/var/my-service/logs/*.log /var/my-service/logs/*/*.log"
          volumeMounts:
            - mountPath: /var/my-service/logs
              name: app-logs
      volumes:
        - name: app-logs
          emptyDir: {}
```
