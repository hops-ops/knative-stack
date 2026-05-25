import models.ai.com.ops.hops.v1alpha1 as hopsv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

_compositionPath = "apis/knativestacks/composition.yaml"
_xrdPath = "apis/knativestacks/definition.yaml"

_items = [
    # =========================================================================
    # Test 1: Minimal config renders operator, NATS, and namespaces
    # (Serving/Eventing Objects gate on observed state so won't render yet)
    # =========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "minimal-defaults"
        spec = {
            compositionPath = _compositionPath
            xrdPath = _xrdPath
            timeoutSeconds = 60
            validate = False
            xr = hopsv1alpha1.KnativeStack {
                metadata.name = "test-minimal"
                spec.clusterName = "my-cluster"
            }
            observedResources = [
                # Composed StorageClass observed-ready — clears the NATS gate
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata = {
                        name = "test-minimal-knative-nats-sc"
                        annotations = {"crossplane.io/composition-resource-name" = "nats-storage-class"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
            ]
            assertResources = [
                # Operator always renders
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-minimal-knative-operator"
                    spec.providerConfigRef = {
                        name = "my-cluster"
                        kind = "ProviderConfig"
                    }
                }
                # NATS renders by default
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-minimal-nats"
                    spec.providerConfigRef = {
                        name = "my-cluster"
                        kind = "ProviderConfig"
                    }
                    spec.forProvider.values = {
                        container.merge.resources.requests = {
                            cpu = "11m"
                            memory = "50Mi"
                        }
                        reloader.merge.resources.requests = {
                            cpu = "11m"
                            memory = "50Mi"
                        }
                        natsBox.container.merge.resources.requests = {
                            cpu = "15m"
                            memory = "100Mi"
                        }
                    }
                }
                # Serving namespace renders by default
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-minimal-knative-serving-namespace"
                    spec.providerConfigRef = {
                        name = "my-cluster"
                        kind = "ProviderConfig"
                    }
                }
                # Eventing namespace renders (distinct from serving)
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-minimal-knative-eventing-namespace"
                }
            ]
        }
    }

    # =========================================================================
    # Test 2: Serving disabled - no serving namespace
    # =========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "serving-disabled"
        spec = {
            compositionPath = _compositionPath
            xrdPath = _xrdPath
            timeoutSeconds = 60
            validate = False
            xr = hopsv1alpha1.KnativeStack {
                metadata.name = "test-no-serving"
                spec = {
                    clusterName = "my-cluster"
                    knativeServing.enabled = False
                }
            }
            observedResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata = {
                        name = "test-no-serving-knative-nats-sc"
                        annotations = {"crossplane.io/composition-resource-name" = "nats-storage-class"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
            ]
            assertResources = [
                # Operator still renders
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-no-serving-knative-operator"
                }
                # NATS still renders
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-no-serving-nats"
                }
                # Eventing namespace renders (serving disabled, so eventing gets its own)
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-no-serving-knative-eventing-namespace"
                }
            ]
        }
    }

    # =========================================================================
    # Test 3: Eventing disabled - no eventing namespace
    # =========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "eventing-disabled"
        spec = {
            compositionPath = _compositionPath
            xrdPath = _xrdPath
            timeoutSeconds = 60
            validate = False
            xr = hopsv1alpha1.KnativeStack {
                metadata.name = "test-no-eventing"
                spec = {
                    clusterName = "my-cluster"
                    knativeEventing.enabled = False
                }
            }
            observedResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata = {
                        name = "test-no-eventing-knative-nats-sc"
                        annotations = {"crossplane.io/composition-resource-name" = "nats-storage-class"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
            ]
            assertResources = [
                # Operator renders
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-no-eventing-knative-operator"
                }
                # Serving namespace still renders
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-no-eventing-knative-serving-namespace"
                }
                # NATS still renders
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-no-eventing-nats"
                }
            ]
        }
    }

    # =========================================================================
    # Test 4: NATS disabled - no NATS Release
    # =========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "nats-disabled"
        spec = {
            compositionPath = _compositionPath
            xrdPath = _xrdPath
            timeoutSeconds = 60
            validate = False
            xr = hopsv1alpha1.KnativeStack {
                metadata.name = "test-no-nats"
                spec = {
                    clusterName = "my-cluster"
                    nats.enabled = False
                }
            }
            assertResources = [
                # Operator renders
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-no-nats-knative-operator"
                }
                # Serving namespace renders
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-no-nats-knative-serving-namespace"
                }
                # Eventing namespace renders
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-no-nats-knative-eventing-namespace"
                }
            ]
        }
    }

    # =========================================================================
    # Test 5: Custom provider config refs propagate to resources
    # =========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "custom-provider-configs"
        spec = {
            compositionPath = _compositionPath
            xrdPath = _xrdPath
            timeoutSeconds = 60
            validate = False
            xr = hopsv1alpha1.KnativeStack {
                metadata.name = "test-custom-pcr"
                spec = {
                    clusterName = "my-cluster"
                    helmProviderConfigRef = {
                        name = "custom-helm"
                        kind = "ClusterProviderConfig"
                    }
                    kubernetesProviderConfigRef = {
                        name = "custom-k8s"
                        kind = "ClusterProviderConfig"
                    }
                }
            }
            observedResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata = {
                        name = "test-custom-pcr-knative-nats-sc"
                        annotations = {"crossplane.io/composition-resource-name" = "nats-storage-class"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
            ]
            assertResources = [
                # Operator uses custom helm provider config
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-custom-pcr-knative-operator"
                    spec.providerConfigRef = {
                        name = "custom-helm"
                        kind = "ClusterProviderConfig"
                    }
                }
                # NATS uses custom helm provider config
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-custom-pcr-nats"
                    spec.providerConfigRef = {
                        name = "custom-helm"
                        kind = "ClusterProviderConfig"
                    }
                }
                # Namespace uses custom kubernetes provider config
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-custom-pcr-knative-serving-namespace"
                    spec.providerConfigRef = {
                        name = "custom-k8s"
                        kind = "ClusterProviderConfig"
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test 6: With observed resources ready, serving/eventing Objects render
    # =========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "serving-eventing-with-observed"
        spec = {
            compositionPath = _compositionPath
            xrdPath = _xrdPath
            timeoutSeconds = 60
            validate = False
            xr = hopsv1alpha1.KnativeStack {
                metadata.name = "test-observed"
                spec.clusterName = "my-cluster"
            }
            observedResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata = {
                        name = "test-observed-knative-operator"
                        annotations = {"crossplane.io/composition-resource-name" = "knative-operator"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata = {
                        name = "test-observed-knative-serving-namespace"
                        annotations = {"crossplane.io/composition-resource-name" = "namespace-knative-serving"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata = {
                        name = "test-observed-knative-eventing-namespace"
                        annotations = {"crossplane.io/composition-resource-name" = "namespace-knative-eventing"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
            ]
            assertResources = [
                # Serving Object renders when operator + namespace ready
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-observed-knative-serving"
                    spec.forProvider.manifest.spec.deployments = [
                        {
                            name = "activator"
                            resources = [{container = "activator", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                        {
                            name = "autoscaler"
                            resources = [{container = "autoscaler", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                        {
                            name = "autoscaler-hpa"
                            resources = [{container = "autoscaler-hpa", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                        {
                            name = "controller"
                            resources = [{container = "controller", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                        {
                            name = "webhook"
                            resources = [{container = "webhook", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                        {
                            name = "net-gateway-api-controller"
                            resources = [{container = "controller", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                        {
                            name = "net-gateway-api-webhook"
                            resources = [{container = "webhook", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                        {
                            name = "net-istio-controller"
                            resources = [{container = "controller", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                        {
                            name = "net-istio-webhook"
                            resources = [{container = "webhook", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                    ]
                }
                # PeerAuthentication: dropped (ambient-mode rebuild — mTLS lives in ztunnel)
                # Eventing Object renders when operator + namespace ready
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-observed-knative-eventing"
                    spec.forProvider.manifest.spec.deployments = [
                        {
                            name = "eventing-controller"
                            resources = [{container = "eventing-controller", requests = {cpu = "15m", memory = "284Mi"}, limits = {memory = "512Mi"}}]
                        }
                        {
                            name = "eventing-webhook"
                            resources = [{container = "eventing-webhook", requests = {cpu = "15m", memory = "309Mi"}, limits = {memory = "512Mi"}}]
                        }
                        {
                            name = "imc-controller"
                            resources = [{container = "controller", requests = {cpu = "23m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                        {
                            name = "imc-dispatcher"
                            resources = [{container = "dispatcher", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                        {
                            name = "job-sink"
                            resources = [{container = "job-sink", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                        {
                            name = "mt-broker-controller"
                            resources = [{container = "mt-broker-controller", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                        {
                            name = "mt-broker-filter"
                            resources = [{container = "filter", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                        {
                            name = "mt-broker-ingress"
                            resources = [{container = "ingress", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                        {
                            name = "request-reply"
                            resources = [{container = "request-reply", requests = {cpu = "15m", memory = "100Mi"}, limits = {memory = "256Mi"}}]
                        }
                    ]
                }
            ]
        }
    }

    # =========================================================================
    # Test 7: Custom labels merge with defaults
    # =========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "custom-labels"
        spec = {
            compositionPath = _compositionPath
            xrdPath = _xrdPath
            timeoutSeconds = 60
            validate = False
            xr = hopsv1alpha1.KnativeStack {
                metadata.name = "test-labels"
                spec = {
                    clusterName = "my-cluster"
                    labels = {
                        "team" = "platform"
                        "env" = "prod"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata = {
                        name = "test-labels-knative-operator"
                        labels = {
                            "hops.ops.com.ai/managed" = "true"
                            "hops.ops.com.ai/knativestack" = "test-labels"
                            "team" = "platform"
                            "env" = "prod"
                        }
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test 8: Custom component names and namespaces
    # =========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "custom-names"
        spec = {
            compositionPath = _compositionPath
            xrdPath = _xrdPath
            timeoutSeconds = 60
            validate = False
            xr = hopsv1alpha1.KnativeStack {
                metadata.name = "test-names"
                spec = {
                    clusterName = "my-cluster"
                    knativeOperator = {
                        name = "kn-op"
                        namespace = "kn-op-ns"
                    }
                    nats = {
                        name = "my-nats"
                        namespace = "my-nats-ns"
                    }
                }
            }
            observedResources = [
                # storageClass.name not overridden, still defaults to "knative-nats"
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata = {
                        name = "test-names-knative-nats-sc"
                        annotations = {"crossplane.io/composition-resource-name" = "nats-storage-class"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
            ]
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-names-kn-op"
                    spec.forProvider.namespace = "kn-op-ns"
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-names-my-nats"
                    spec.forProvider.namespace = "my-nats-ns"
                }
            ]
        }
    }

    # =========================================================================
    # Test 9: All optional components disabled - only operator renders
    # =========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "all-optional-disabled"
        spec = {
            compositionPath = _compositionPath
            xrdPath = _xrdPath
            timeoutSeconds = 60
            validate = False
            xr = hopsv1alpha1.KnativeStack {
                metadata.name = "test-bare"
                spec = {
                    clusterName = "my-cluster"
                    knativeServing.enabled = False
                    knativeEventing.enabled = False
                    nats.enabled = False
                }
            }
            assertResources = [
                # Only operator should render
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-bare-knative-operator"
                }
            ]
        }
    }

    # =========================================================================
    # Test 10: NATS gates on StorageClass — full contract.
    # SC composes day-zero (asserted). NATS Release renders only after SC is
    # observed-ready. The teardown Usage (delete-nats-before-storage-class)
    # renders only when both NATS and SC are observed-ready, so its presence
    # is end-to-end proof the gate has cleared.
    # =========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "nats-gates-on-storage-class"
        spec = {
            compositionPath = _compositionPath
            xrdPath = _xrdPath
            timeoutSeconds = 60
            validate = False
            xr = hopsv1alpha1.KnativeStack {
                metadata.name = "test-nats-gate"
                spec.clusterName = "my-cluster"
            }
            observedResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata = {
                        name = "test-nats-gate-knative-nats-sc"
                        annotations = {"crossplane.io/composition-resource-name" = "nats-storage-class"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata = {
                        name = "test-nats-gate-nats"
                        annotations = {"crossplane.io/composition-resource-name" = "nats"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
            ]
            assertResources = [
                # SC Object renders day-zero
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-nats-gate-knative-nats-sc"
                }
                # NATS Release renders once SC is observed-ready
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-nats-gate-nats"
                }
                # Teardown Usage renders only when both observed-ready
                {
                    apiVersion = "protection.crossplane.io/v1beta1"
                    kind = "Usage"
                    metadata.name = "test-nats-gate-delete-nats-before-storage-class"
                }
            ]
        }
    }

    # =========================================================================
    # Test 11: nodePool adds operator/NATS placement and renders NodePool.
    # =========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "nodepool-adds-operator-nats-placement"
        spec = {
            compositionPath = _compositionPath
            xrdPath = _xrdPath
            timeoutSeconds = 60
            validate = False
            xr = hopsv1alpha1.KnativeStack {
                metadata.name = "test-nodepool"
                spec = {
                    clusterName = "my-cluster"
                    nodePool.enabled = True
                }
            }
            observedResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata = {
                        name = "test-nodepool-knative-nats-sc"
                        annotations = {"crossplane.io/composition-resource-name" = "nats-storage-class"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
            ]
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-nodepool-knative-operator"
                    spec.forProvider.values.knative_operator.knative_operator = {
                        affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms = [
                            {matchExpressions = [{key = "workload-type", operator = "In", values = ["knative"]}]}
                        ]
                        tolerations = [
                            {
                                key = "knative"
                                operator = "Equal"
                                value = "true"
                                effect = "NoSchedule"
                            }
                        ]
                        resources.requests = {
                            cpu = "15m"
                            memory = "100Mi"
                        }
                    }
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-nodepool-nats"
                    spec.forProvider.values.podTemplate.merge.spec = {
                        nodeSelector = {"workload-type" = "knative"}
                        tolerations = [
                            {
                                key = "knative"
                                operator = "Equal"
                                value = "true"
                                effect = "NoSchedule"
                            }
                        ]
                    }
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-nodepool-nodepool-knative"
                    spec.forProvider.manifest = {
                        apiVersion = "karpenter.sh/v1"
                        kind = "NodePool"
                        metadata.name = "hops-knative"
                        spec.template.metadata.labels = {"workload-type" = "knative"}
                    }
                }
                {
                    apiVersion = "protection.crossplane.io/v1beta1"
                    kind = "Usage"
                    metadata.name = "test-nodepool-delete-nats-before-nodepool"
                }
            ]
        }
    }
]
items = _items
