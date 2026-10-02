# NVIDIA DinD dev image

Source: https://github.com/pstjohn/nvidia-dind (fork of Extrality/nvidia-dind).
The build checkout is `/home/pstjohn/misc/nvidia-dind` on `ssh bo`.
The published base is `nvcr.io/1015084509601350/nvidia-dind:13.1`.

CUDA 13.1.1 / Ubuntu 24.04 with Docker and NVIDIA Container Toolkit. Requires
privileged mode and NVIDIA Container Toolkit on the host.

Baked-in dev tools: htop, tmux, vim, gh, git, jq, ripgrep, rsync, less,
build-essential, Python/venv, sudo, tini, procps, util-linux, unzip, curl and
xz-utils. Node LTS and npm, Pi, Paseo, AWS CLI (`aws s3` including PBSS), and
Lepton CLI are installed globally. Versions are Docker build arguments.

Build and verify on bo, using its existing NGC registry login:

```bash
cd /home/pstjohn/misc/nvidia-dind
image=nvcr.io/1015084509601350/nvidia-dind:13.1-dev-20261002
DOCKER_BUILDKIT=1 docker build --progress=plain -t "$image" .
docker run --rm --entrypoint bash "$image" -lc 'node --version; npm --version; pi --version; paseo --version; aws --version; lep --help >/dev/null; gh --version; command -v htop tmux rg tini nvidia-ctk dockerd'
docker push "$image"
```

Publish a new dated tag; retain `:13.1` for existing pods until the replacement
passes validation on the target Lepton pod. The inherited GitHub Actions workflow
still targets `ghcr.io/extrality/nvidia-dind`; it does **not** publish this NGC tag.

Keep credentials, SSH keys, Teleport enrollment/configuration, mounted-directory
ownership, persistent Paseo state, and Docker storage-driver probing at runtime.

The 2026-10-02 image passed CLI checks and the native bootstrap / nested GPU
smoke test on bo, exposing both RTX 5090s through an inner Ubuntu container.
Lepton-native Teleport enrollment and H100 validation remain deployment checks.

The coding-agent fleet still manages user configuration, skills, extensions and
CLI upgrades. Codex and Claude installation remains with personal provisioning /
fleet. The Lepton-native Teleport installer remains a runtime step because it
registers the individual pod with platform-provided identity.
