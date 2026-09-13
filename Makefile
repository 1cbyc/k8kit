SHELL := /bin/bash
.DEFAULT_GOAL := check

TOOLS := $(CURDIR)/.tools
BUILD := $(CURDIR)/build
KUSTOMIZE := $(TOOLS)/kustomize
KUBECONFORM := $(TOOLS)/kubeconform
CONFTEST := $(TOOLS)/conftest
KUSTOMIZE_VERSION := 5.8.1
KUBECONFORM_VERSION := 0.8.0
CONFTEST_VERSION := 0.70.0
KUBERNETES_VERSION := 1.34.0
EXAMPLE_IMAGE := traefik/whoami@sha256:c4717a8d1f0134a7444e24f881160e033991f23027c6c5a9a3f8fd22e70d1d44
TRIVY_IMAGE := aquasec/trivy:0.74.0@sha256:62b1e65e8869bc4b4c6aa4fa2b21595256c7c2f6018a9d9ad61caf87187c1969

.PHONY: tools render schema policy negative security smoke check ci clean

tools: $(KUSTOMIZE) $(KUBECONFORM) $(CONFTEST)

$(TOOLS):
	mkdir -p $@

$(KUSTOMIZE): | $(TOOLS)
	curl -fsSLo $(TOOLS)/kustomize.tar.gz https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v$(KUSTOMIZE_VERSION)/kustomize_v$(KUSTOMIZE_VERSION)_linux_amd64.tar.gz
	echo '029a7f0f4e1932c52a0476cf02a0fd855c0bb85694b82c338fc648dcb53a819d  $(TOOLS)/kustomize.tar.gz' | sha256sum -c -
	tar -xzf $(TOOLS)/kustomize.tar.gz -C $(TOOLS) kustomize
	rm $(TOOLS)/kustomize.tar.gz

$(KUBECONFORM): | $(TOOLS)
	curl -fsSLo $(TOOLS)/kubeconform.tar.gz https://github.com/yannh/kubeconform/releases/download/v$(KUBECONFORM_VERSION)/kubeconform-linux-amd64.tar.gz
	echo '9bc2bffbf71f261128533edaf912153948b7ff238f9a531ae6d34466ec287883  $(TOOLS)/kubeconform.tar.gz' | sha256sum -c -
	tar -xzf $(TOOLS)/kubeconform.tar.gz -C $(TOOLS) kubeconform
	rm $(TOOLS)/kubeconform.tar.gz

$(CONFTEST): | $(TOOLS)
	curl -fsSLo $(TOOLS)/conftest.tar.gz https://github.com/open-policy-agent/conftest/releases/download/v$(CONFTEST_VERSION)/conftest_$(CONFTEST_VERSION)_Linux_x86_64.tar.gz
	echo 'e738506fd808f7dc9794ce8e325f89b14932891a4841fe45f1f24c4a9bb3ed96  $(TOOLS)/conftest.tar.gz' | sha256sum -c -
	tar -xzf $(TOOLS)/conftest.tar.gz -C $(TOOLS) conftest
	rm $(TOOLS)/conftest.tar.gz

render: tools
	mkdir -p $(BUILD)
	$(KUSTOMIZE) build base > $(BUILD)/base.yaml
	$(KUSTOMIZE) build examples/development > $(BUILD)/development.yaml
	$(KUSTOMIZE) build examples/production > $(BUILD)/production.yaml

schema: render
	$(KUBECONFORM) -strict -summary -kubernetes-version $(KUBERNETES_VERSION) $(BUILD)/*.yaml

policy: render
	$(CONFTEST) test --all-namespaces --policy policy $(BUILD)/*.yaml

negative: tools
	@if $(CONFTEST) test --all-namespaces --policy policy testdata/insecure.yaml >/dev/null 2>&1; then echo 'insecure fixture unexpectedly passed'; exit 1; else echo 'insecure fixture rejected'; fi

check: schema policy negative

security: render
	docker run --rm -v $(BUILD):/src:ro $(TRIVY_IMAGE) config --exit-code 1 --severity HIGH,CRITICAL /src

smoke:
	@cid=$$(docker run -d --read-only --user 101:101 --cap-drop ALL --security-opt no-new-privileges -p 127.0.0.1::8080 $(EXAMPLE_IMAGE) --port=8080); trap 'docker rm -f $$cid >/dev/null 2>&1 || true' EXIT; port=$$(docker port $$cid 8080/tcp | sed 's/.*://'); for attempt in $$(seq 1 20); do curl -fsS http://127.0.0.1:$$port/healthz >/dev/null && curl -fsS http://127.0.0.1:$$port/readyz >/dev/null && break; sleep 0.25; done; curl -fsS http://127.0.0.1:$$port/healthz >/dev/null; test "$$(docker inspect $$cid --format '{{.Config.User}} {{.HostConfig.ReadonlyRootfs}} {{json .HostConfig.CapDrop}} {{json .HostConfig.SecurityOpt}}')" = '101:101 true ["ALL"] ["no-new-privileges"]'; echo 'hardened example smoke test passed'

ci: check security smoke

clean:
	rm -rf $(BUILD)
