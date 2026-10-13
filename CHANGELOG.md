### What's changed in v1.6.2

* fix(deps): update helm release nats to v2.15.1 (#24) (by @renovate[bot])

  NATS chart 2.14.6 -> 2.15.1 (nats-server 2.15.1, config-reloader 0.24.0, nats-box 0.20.0; templates unchanged). XR renders this Release, so fix(deps) to cut a release. Reviewed vs our defaults (3-replica cluster, JetStream file store, NatsJetStreamChannel): 2.15 per-stream default max_consumers=1000 is far above per-channel subscription counts; no scale/move ops in our usage so the 2.14.7-first upgrade recommendation (scale/move stall in mixed versions) does not bite. validate/test/e2e green.


See full diff: [v1.6.1...v1.6.2](https://github.com/hops-ops/knative-stack/compare/v1.6.1...v1.6.2)
