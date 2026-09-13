package main

import rego.v1

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  not startswith(container.image, "sha256:")
  not contains(container.image, "@sha256:")
  msg := sprintf("Deployment %s container %s must use a digest-pinned image", [input.metadata.name, container.name])
}

deny contains msg if {
  input.kind == "Deployment"
  not input.spec.template.spec.securityContext.runAsNonRoot
  msg := sprintf("Deployment %s must run as non-root", [input.metadata.name])
}

deny contains msg if {
  input.kind == "Deployment"
  input.spec.template.spec.automountServiceAccountToken != false
  msg := sprintf("Deployment %s must disable service account token mounting", [input.metadata.name])
}

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  container.securityContext.allowPrivilegeEscalation != false
  msg := sprintf("Deployment %s container %s permits privilege escalation", [input.metadata.name, container.name])
}

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  container.securityContext.readOnlyRootFilesystem != true
  msg := sprintf("Deployment %s container %s needs a read-only root filesystem", [input.metadata.name, container.name])
}

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  not container.resources.requests.cpu
  msg := sprintf("Deployment %s container %s has no CPU request", [input.metadata.name, container.name])
}

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  not container.resources.limits.memory
  msg := sprintf("Deployment %s container %s has no memory limit", [input.metadata.name, container.name])
}

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  not container.startupProbe
  msg := sprintf("Deployment %s container %s has no startup probe", [input.metadata.name, container.name])
}

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  not container.livenessProbe
  msg := sprintf("Deployment %s container %s has no liveness probe", [input.metadata.name, container.name])
}

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  not container.readinessProbe
  msg := sprintf("Deployment %s container %s has no readiness probe", [input.metadata.name, container.name])
}

deny contains msg if {
  input.kind == "Service"
  input.spec.type != "ClusterIP"
  msg := sprintf("Service %s must remain internal by default", [input.metadata.name])
}
