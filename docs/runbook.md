# Workload runbook

## Before rollout

- Render the intended overlay and inspect every changed object.
- Confirm the image digest, container user, port, probe paths, resource limits, and required writable paths with an image smoke test.
- Validate against the target cluster with server-side dry run.
- Confirm the namespace enforces the expected Pod Security profile and the cluster network plugin enforces NetworkPolicy.
- Confirm callers and required egress destinations match explicit policy selectors.
- Confirm metrics are available before enabling the HorizontalPodAutoscaler.

## Verify rollout

Apply the reviewed rendered file through the environment's delivery process. Watch Deployment rollout status and confirm all replicas become Available. Exercise liveness, readiness, and one representative request through the real service path. Check restart count, warning events, resource saturation, denied connections, and autoscaler conditions.

## Diagnose

Pending pods commonly indicate resource pressure, restricted topology, or Pod Security rejection. Ready replicas stuck below the target commonly indicate a wrong port or readiness path. Crash loops commonly indicate a non-root or read-only-filesystem incompatibility. DNS-only egress is intentional; timeouts to databases or external endpoints require a reviewed narrow egress addition.

## Roll back

Revert to the last reviewed base revision and image digest, render again, inspect the diff, and apply it. Watch the replacement rollout and repeat the representative request. If the new release changed an external schema or irreversible data, application rollback may be unsafe even when Kubernetes accepts the old manifest.

## Remove safely

Inventory externally managed ingress, secrets, policies, and data before deleting namespaced workload objects. Remove the rendered objects without deleting the namespace first. Delete the namespace only when its complete contents and retention requirements are understood. This asset creates no paid infrastructure by itself, but running replicas and load balancers added by a consumer can incur cost.
