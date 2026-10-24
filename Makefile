.PHONY: image push

IMAGE   := docker-registry.home.thomas.sh/lidarr-arr-scripts
VERSION := $(shell git rev-parse --short HEAD)
HEAD    := $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)
DIRTY   := $(shell git diff --quiet 2>/dev/null && echo "" || echo "-dirty")

image:
	podman build --build-arg GIT_HEAD=$(HEAD)$(DIRTY) -t $(IMAGE):$(VERSION) -t $(IMAGE):latest .

push: image
	podman push $(IMAGE):$(VERSION)
	podman push $(IMAGE):latest
