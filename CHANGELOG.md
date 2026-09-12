### What's changed in v1.6.1

* chore(deps): migrate workflows-crossplane to hops-ops@v3.2.0 (by @renovate[bot])

  * chore(deps): update unbounded-tech/workflows-crossplane action to v3

  * chore(deps): migrate workflows-crossplane to hops-ops@v3.2.0

  ---------

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>
  Co-authored-by: Patrick Lee Scott <pat@patscott.io>

* chore(deps): update unbounded-tech/workflow-vnext-tag action to v1.22.3 (#16) (by @renovate[bot])

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>

* fix(deps): adopt knative-operator 1.23.1 (chart URL pin) (#22) (by @patrickleet)

  * chore(deps): update helm release knative-operator to v1.23.1

  * fix(deps): adopt knative-operator 1.23.1 without doubled v prefix

  Renovate set $operatorChartVersion to v1.23.1, but the Helm url already prefixes knative-v%s. Chart.yaml version is 1.23.1. Keep the 1.21 values keys (knative_operator.{knative_operator,operator_webhook}).

  ---------

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>


See full diff: [v1.6.0...v1.6.1](https://github.com/hops-ops/knative-stack/compare/v1.6.0...v1.6.1)
