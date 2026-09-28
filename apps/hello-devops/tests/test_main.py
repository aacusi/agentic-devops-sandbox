"""Tests for the hello-devops HTTP surface.

These exist so that phase 6 CI has something real to run, and so that the probe
contract Kubernetes depends on cannot be broken silently.

TestClient enters the app's lifespan, so readiness is true inside the `with` block.
"""

from __future__ import annotations

from fastapi.testclient import TestClient

from hello_devops import __version__
from hello_devops.main import app


def test_healthz_is_always_ok() -> None:
    with TestClient(app) as client:
        response = client.get("/healthz")
    assert response.status_code == 200
    assert response.text == "ok"


def test_readyz_is_ok_once_started() -> None:
    with TestClient(app) as client:
        response = client.get("/readyz")
    assert response.status_code == 200
    assert response.text == "ready"


def test_readyz_is_503_before_startup() -> None:
    """Without entering the lifespan the app must report itself as not ready.

    This is the behaviour that lets Kubernetes hold traffic back during a rollout.
    """
    client = TestClient(app)
    response = client.get("/readyz")
    assert response.status_code == 503
    assert response.text == "not ready"


def test_version_endpoint_matches_package_version() -> None:
    with TestClient(app) as client:
        response = client.get("/version")
    assert response.status_code == 200
    assert response.text == __version__


def test_api_info_reports_expected_fields() -> None:
    with TestClient(app) as client:
        response = client.get("/api/info")
    assert response.status_code == 200
    payload = response.json()
    for field in (
        "app",
        "version",
        "environment",
        "instance",
        "hostname",
        "pod_name",
        "node_name",
        "ready",
    ):
        assert field in payload, f"missing field: {field}"
    assert payload["app"] == "hello-devops"
    assert payload["ready"] is True
    assert payload["instance"]


def test_index_renders_version() -> None:
    with TestClient(app) as client:
        response = client.get("/")
    assert response.status_code == 200
    assert "hello-devops" in response.text
    assert __version__ in response.text
