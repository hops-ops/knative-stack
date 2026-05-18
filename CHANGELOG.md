### What's changed in v1.1.0

* fix: bump eventing-webhook memory limit from 200Mi to 512Mi (by @patrickleet)

  Chart default of 200Mi OOMKills under modest ApiServerSource / Trigger
  reconcile load. Inject a deployments override into the KnativeEventing
  CR default spec so the webhook stays up.

* feat: Burstable resource defaults for NATS (container + reloader) (by @patrickleet)

  NATS chart ships container + reloader as BestEffort by default. Sized
  via the chart's container.merge / reloader.merge strategic-merge-patch
  hooks. JetStream-backed NATS is restart-recoverable thanks to PVC
  persistence; Burstable memory is fine.

  Verified on pat-local: statefulset rolled pat-local-nats-2 to Burstable
  with nats container at 100m/256Mi request, 500m/512Mi limit; reloader
  at 10m/32Mi request, 50m/64Mi limit. Other replicas rolling.

  Implements [[tasks/cluster-wide-resource-right-sizing-p95-observation]] tier-1 #7


See full diff: [v1.0.0...v1.1.0](https://github.com/hops-ops/knative-stack/compare/v1.0.0...v1.1.0)
