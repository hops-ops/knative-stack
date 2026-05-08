import datetime
import math
import models.ai.com.ops.hops.v1alpha1 as stacksv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

# ==============================================================================
# E2E Test for Knative (Kubernetes-only)
#
# Dependency chain (kind cluster has no Gateway API CRDs by default):
#   1. gateway-api-stack@v0.1.0  → installs Gateway API CRDs via Helm
#   2. istio-stack@v1.0.0        → installs Istio Ambient (depends on Gateway API CRDs)
#   3. knative-stack (this repo) → net-gateway-api, depends on both above
#
# initResources installs the dependency Configuration packages.
# extraResources defines the dependency XRs (NOT deleted on cleanup, so the
# stack stays warm). manifests holds the KnativeStack XR being tested.
#
# All in-cluster: Helm + Kubernetes providers via InjectedIdentity.
#
# Run: make e2e
# Run without cleanup: up test run tests/e2etest-knative --e2e --skip-control-plane-cleanup
# ==============================================================================
_now = str(int(math.floor(datetime.ticks())))
_test_name = "e2e-knative-" + _now
_istio_name = "e2e-istio-" + _now
_gwapi_name = "e2e-gwapi-" + _now

_items = [
    metav1alpha1.E2ETest {
        metadata.name = "knative-e2e"
        spec = {
            crossplane = {
                autoUpgrade.channel = "Rapid"
            }
            defaultConditions = ["Ready"]
            # 60 minutes — gateway-api CRDs + Istio Ambient + Knative Operator/Serving/Eventing
            timeoutSeconds = 3600
            # 30 minutes
            cleanupTimeoutSeconds = 1800
            skipDelete = False
            # ==============================================================
            # initResources: dependency Configuration packages
            # ==============================================================
            initResources = [
                # gateway-api-stack — provides GatewayAPIStack XRD; the XR
                # installs the Gateway API CRDs (gateway.networking.k8s.io/v1).
                {
                    apiVersion = "pkg.crossplane.io/v1"
                    kind = "Configuration"
                    metadata = {
                        name = "gateway-api-stack"
                    }
                    spec = {
                        package = "ghcr.io/hops-ops/gateway-api-stack:v0.1.0"
                    }
                }
                # istio-stack — provides IstioStack XRD (ambient mode + Gateway API).
                {
                    apiVersion = "pkg.crossplane.io/v1"
                    kind = "Configuration"
                    metadata = {
                        name = "istio-stack"
                    }
                    spec = {
                        package = "ghcr.io/hops-ops/istio-stack:v1.0.0"
                    }
                }
            ]
            # ==============================================================
            # extraResources: RBAC, ProviderConfigs, dependency XRs
            # NOT deleted on cleanup — kept across test runs.
            # ==============================================================
            extraResources = [
                # cluster-admin to crossplane-system SAs so providers can install
                # charts and create cluster-scoped resources.
                {
                    apiVersion = "rbac.authorization.k8s.io/v1"
                    kind = "ClusterRoleBinding"
                    metadata.name = "crossplane-system-cluster-admin"
                    roleRef = {
                        apiGroup = "rbac.authorization.k8s.io"
                        kind = "ClusterRole"
                        name = "cluster-admin"
                    }
                    subjects = [
                        {
                            kind = "Group"
                            name = "system:serviceaccounts:crossplane-system"
                            apiGroup = "rbac.authorization.k8s.io"
                        }
                    ]
                }
                # Helm ProviderConfig — in-cluster identity.
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "ProviderConfig"
                    metadata = {
                        name = "default"
                        namespace = "default"
                    }
                    spec = {
                        credentials = {
                            source = "InjectedIdentity"
                        }
                    }
                }
                # Kubernetes ProviderConfig — in-cluster identity.
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "ProviderConfig"
                    metadata = {
                        name = "default"
                        namespace = "default"
                    }
                    spec = {
                        credentials = {
                            source = "InjectedIdentity"
                        }
                    }
                }
                # GatewayAPIStack XR — installs Gateway API CRDs via Helm.
                # Must reach Ready before IstioStack and KnativeStack can compose
                # Gateway / HTTPRoute resources successfully.
                {
                    apiVersion = "hops.ops.com.ai/v1alpha1"
                    kind = "GatewayAPIStack"
                    metadata = {
                        name = _gwapi_name
                        namespace = "default"
                    }
                    spec = {
                        clusterName = "default"
                        labels = {
                            "hops.ops.com.ai/e2etest" = "true"
                            "hops.ops.com.ai/test-run" = _now
                        }
                        helmProviderConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                    }
                }
                # IstioStack XR — Ambient install. Skips the platform Gateway
                # resource (ingressGateway disabled) since this e2e exercises
                # Knative's own knative-local-gateway, and a public ingress
                # gateway isn't needed inside a kind cluster.
                {
                    apiVersion = "hops.ops.com.ai/v1alpha1"
                    kind = "IstioStack"
                    metadata = {
                        name = _istio_name
                        namespace = "default"
                    }
                    spec = {
                        clusterName = "default"
                        labels = {
                            "hops.ops.com.ai/e2etest" = "true"
                            "hops.ops.com.ai/test-run" = _now
                        }
                        helmProviderConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                        kubernetesProviderConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                        istiod = {
                            values = {
                                pilot = {
                                    resources = {
                                        requests = {cpu = "10m", memory = "64Mi"}
                                    }
                                }
                            }
                        }
                        ingressGateway = {
                            enabled = False
                        }
                    }
                }
            ]
            # ==============================================================
            # manifests: KnativeStack XR (the test subject)
            # Deleted during cleanup (unless --skip-delete).
            # ==============================================================
            manifests = [
                stacksv1alpha1.KnativeStack {
                    metadata = {
                        name = _test_name
                        namespace = "default"
                    }
                    spec = {
                        clusterName = "default"
                        labels = {
                            "hops.ops.com.ai/e2etest" = "true"
                            "hops.ops.com.ai/test-run" = _now
                        }
                        helmProviderConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                        kubernetesProviderConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                        knativeServing.enabled = True
                        knativeEventing.enabled = True
                    }
                }
            ]
        }
    }
]
items = _items
