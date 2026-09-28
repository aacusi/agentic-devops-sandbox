"""Configuration, read from the environment only (12-factor).

Nothing here reads a file, a secret store or a cloud metadata endpoint. Every value
has a safe default so the app starts identically on a laptop, in Docker and in
Kubernetes — only the environment differs.

POD_NAME and NODE_NAME are empty on a laptop and populated in Kubernetes via the
downward API (see k8s/hello-devops/base/deployment.yaml). That difference is the
point: it is how you will watch pods being replaced during a rollout.
"""

from __future__ import annotations

import os
import socket
from dataclasses import dataclass

from hello_devops import __version__


@dataclass(frozen=True)
class Settings:
    """Immutable snapshot of the environment, resolved once at import time."""

    app_name: str
    app_version: str
    app_env: str
    pod_name: str
    node_name: str
    hostname: str
    log_level: str

    @property
    def instance(self) -> str:
        """Best available identity for 'which copy of the app am I talking to?'."""
        return self.pod_name or self.hostname


def load_settings() -> Settings:
    return Settings(
        app_name=os.getenv("APP_NAME", "hello-devops"),
        # APP_VERSION is injected by the image build / manifest so the running
        # container can state exactly which artifact it came from.
        app_version=os.getenv("APP_VERSION", __version__),
        app_env=os.getenv("APP_ENV", "local"),
        pod_name=os.getenv("POD_NAME", ""),
        node_name=os.getenv("NODE_NAME", ""),
        hostname=socket.gethostname(),
        log_level=os.getenv("LOG_LEVEL", "info"),
    )


settings = load_settings()
