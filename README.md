# k8kit

`k8kit` is a Kustomize base for a stateless HTTP workload. It gives service repositories a reviewable starting point for rollout, health, resources, identity, disruption, and network boundaries without hiding the rendered Kubernetes objects.

## Intended use

Use the base for services that already expose separate liveness and readiness endpoints and can run with an immutable root filesystem as a non-root user. The examples show one low-cost development overlay and one multi-zone production overlay for an `orders` service.

The base deliberately does not create ingress, secrets, persistent storage, certificate resources, cluster-wide policy, or a Kubernetes cluster. It does not decide how credentials enter a workload. Those choices belong to the consuming environment and must be reviewed there.

## Adopt it

1. Copy `base` into the service repository or reference a reviewed immutable Git revision.
2. Create an overlay following `examples/development` or `examples/production`.
3. Replace `app-image` with the service image by digest. Keep the digest, probes, port, user, and filesystem behavior aligned with the image.
4. Patch the namespace, names, resources, configuration, and network peers for the service.
5. Run `make check`, inspect the rendered file under `build`, and use a server-side dry run against the target cluster before applying.

The example image is the published multi-platform digest for `traefik/whoami:v1.12.0`. It listens on port 8080 and answers the example health paths, so the manifests form a runnable consumer scenario. Consumers must still supply and test their own application endpoints.

## Guarantees checked locally

`make check` downloads checksum-verified Kustomize 5.8.1, Kubeconform 0.8.0, and Conftest 0.70.0 into the ignored `.tools` directory. It renders the base and both overlays, validates every object against strict Kubernetes 1.34 schemas, checks workload policies, and proves that the insecure fixture is rejected. `make ci` also scans rendered objects for high and critical misconfigurations and runs the example image as UID 101 with a read-only root filesystem, no Linux capabilities, and no-new-privileges before exercising both health paths.

Kubeconform covers the published API schema, not every admission or controller rule. Before a rollout, run a server-side dry run against the same Kubernetes minor version as production and validate any installed custom resources with their schemas.

## Consumer contract

The stable customization points are the `app-image` image name, the `service` resource name, the named `http` port, and overlay patches. The workload requires `/healthz` and `/readyz`, listens on port 8080, writes no required state to its root filesystem, and handles termination within 30 seconds. A network client needs the label `networking.k8kit/access: service`. Consumers that change these contracts must patch all related probes, Services, policies, and operational checks together.

See `docs/design.md` for tradeoffs and compatibility and `docs/runbook.md` for rollout, verification, rollback, and removal.
