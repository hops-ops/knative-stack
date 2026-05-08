### What's changed in v1.0.0

* feat: rebuild on net-gateway-api with per-namespace wildcard auto-TLS (by @patrickleet)

  BREAKING CHANGE: Switches Knative Serving's networking layer from net-istio (sidecar) to
  net-gateway-api. Knative now emits Gateway API HTTPRoutes attached to a
  platform Gateway provisioned by istio-stack (ambient + Gateway API).
  PeerAuthentication is dropped — ambient handles mTLS at the node via ztunnel.

  New schema:
  - spec.gatewayRef.{name,namespace,gatewayClassName} — parent Gateway
    (defaults: platform / istio-ingress / istio).
  - spec.autoTls.{enabled,namespaceSelector} — per-namespace wildcard auto-TLS.
    When on, Knative emits a *.<ns>.<hostedZone> Certificate per matching
    namespace; cert-manager fulfills via DNS-01; net-gateway-api wires the
    Secret into the Gateway TLS listener. Scales linearly with tenancy and
    avoids Let's Encrypt rate-limit pressure of per-service mode.
  - New 225-knative-local-gateway.yaml.gotmpl composes the cluster-local
    Gateway in knative-serving namespace.

  Implements [[tasks/knative-stack-net-gateway-api-rebuild]]

  BREAKING CHANGE: net-istio is no longer supported. spec.* shape changed —
  gatewayRef and autoTls are new; config.istio is replaced by config.gateway.
  Consumers must switch to ambient + Gateway API; istio-stack v2+ is required.

* fix(e2e): wire gateway-api-stack + istio-stack v1.0.0 as initResources/deps (by @patrickleet)

  Knative e2e was failing because the kind cluster lacks Gateway API CRDs
  required by knative-local-gateway. Restructure the e2e to install the full
  dependency chain:

    1. gateway-api-stack@v0.1.0 → Configuration package + GatewayAPIStack XR
       (installs Gateway API CRDs via Helm)
    2. istio-stack@v1.0.0 → Configuration package + IstioStack XR
       (ambient mode; ingressGateway disabled — knative uses its own
       knative-local-gateway, no public ingress needed inside kind)
    3. KnativeStack → the test subject

  Also updates stale provider config refs to the new helm/kubernetes split
  that landed with the istio + knative ambient rewrites.

* fix(e2e): disable knativeEventing in e2e (heavy reconcile, not on critical path) (by @patrickleet)

* fix(e2e): bump timeout to 90 min for full Istio Ambient + Knative install (by @patrickleet)

* ci: bump e2e timeout/cleanup to 60min for full Knative+Istio+GW-API unwind (by @patrickleet)

* ci: split e2e cleanup — KnativeStack first, then IstioStack/GatewayAPIStack (by @patrickleet)

  Mirrors the aws-observe-stack pattern. KnativeStack cleanup runs first under
  cleanup-timeout-minutes (30); the heavy infra (IstioStack + GatewayAPIStack)
  gets torn down in a separate Delete extra resources phase under
  delete-extra-resources-timeout-minutes (30). Total cleanup budget unchanged
  but each phase has clear ownership; test phase always returns to a clean
  managed-resource state on a kind cluster.

  The previous 60min cleanup timed out on releases/<name>-istio-base — the
  istio Helm release teardown was racing with KnativeStack's own teardown and
  neither could complete.


See full diff: [v0.8.0...v1.0.0](https://github.com/hops-ops/knative-stack/compare/v0.8.0...v1.0.0)
