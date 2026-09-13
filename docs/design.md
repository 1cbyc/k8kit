# Design and compatibility

## Why Kustomize

The asset serves owned workloads whose teams need to inspect ordinary Kubernetes YAML and maintain a small number of environment differences. Kustomize preserves that direct model and keeps the base unaware of consumers. A Helm chart would add a second configuration language and packaging lifecycle that this scope does not need.

## Boundaries

The base selects a dedicated service account but creates no Role or RoleBinding. Its token is not mounted. Namespace Pod Security labels request the restricted profile. The container drops Linux capabilities, blocks privilege escalation, runs as UID and GID 101, uses the runtime-default seccomp profile, and expects a read-only root filesystem.

The NetworkPolicy isolates selected pods in both directions. Inbound callers need an explicit label. Outbound traffic is limited to TCP and UDP DNS in the `kube-system` namespace. A service that needs a database, telemetry collector, or external API must add narrow egress rules. Enforcement requires a network plugin that implements NetworkPolicy.

The rolling strategy keeps existing capacity during replacement. The production overlay adds conservative autoscaling and zone-aware scheduling. A disruption budget helps with voluntary evictions but does not constrain Deployment rollouts or guarantee capacity during involuntary failures.

## Compatibility

Rendered objects use stable APIs available in Kubernetes 1.34. Validate against the exact target minor before adoption. The `unhealthyPodEvictionPolicy` field requires Kubernetes 1.27 or later. Removing it is the compatibility path for an older cluster, but that changes node-drain behavior and must be reviewed.

Treat resource names, label keys, the named port, image token, probes, and ConfigMap references as the consumer interface. Upgrade by rendering the old and new revisions, reviewing their object diff, validating with the target API server, and rolling out to a non-production namespace first.

## Rollback

Keep the previous base Git revision and image digest in version control. Reverting both restores the prior desired state. API field removal and resource renaming can be destructive, so inspect the rendered diff before applying. Do not use pruning during the first rollout of an upgrade unless removed objects have been explicitly approved.
