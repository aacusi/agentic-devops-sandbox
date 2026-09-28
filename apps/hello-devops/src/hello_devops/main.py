"""HTTP surface for hello-devops.

Liveness vs readiness is the one piece of real engineering in this app, because it
is what makes a zero-downtime Kubernetes rollout possible:

* /healthz  liveness  — "is this process broken?" If it fails, Kubernetes RESTARTS
                        the container. It must never depend on anything external,
                        or an outage elsewhere turns into a restart storm here.
* /readyz   readiness — "should this process receive traffic right now?" If it
                        fails, Kubernetes removes the pod from the Service
                        endpoints but leaves it running. This is where you would
                        check a database connection in a real app.

On shutdown we flip readiness to false first, so the pod is drained from the
Service before the process actually stops.
"""

from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, status
from fastapi.responses import HTMLResponse, JSONResponse, PlainTextResponse

from hello_devops.config import settings

logging.basicConfig(
    level=settings.log_level.upper(),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
log = logging.getLogger("hello_devops")

# Module-level readiness flag. A single boolean is enough while the app has no
# dependencies; when it gains one, this becomes a real check.
_ready = False


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    global _ready
    log.info(
        "starting app_name=%s version=%s env=%s instance=%s",
        settings.app_name,
        settings.app_version,
        settings.app_env,
        settings.instance,
    )
    _ready = True
    try:
        yield
    finally:
        _ready = False
        log.info("shutting down — readiness withdrawn")


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    summary="Sample workload for the agentic DevOps sandbox",
    lifespan=lifespan,
)


def _info() -> dict[str, str | bool]:
    return {
        "app": settings.app_name,
        "version": settings.app_version,
        "environment": settings.app_env,
        "instance": settings.instance,
        "hostname": settings.hostname,
        "pod_name": settings.pod_name,
        "node_name": settings.node_name,
        "ready": _ready,
    }


@app.get("/", response_class=HTMLResponse, include_in_schema=False)
async def index() -> HTMLResponse:
    """Human-readable status page.

    Deliberately shows version, environment and instance in large text: during a
    rollout you refresh this page and watch the values change.
    """
    info = _info()
    rows = "".join(
        f"<tr><th>{key}</th><td>{value if value != '' else '&mdash;'}</td></tr>"
        for key, value in info.items()
    )
    return HTMLResponse(
        f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>{info["app"]} {info["version"]}</title>
  <style>
    body {{ font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
            margin: 3rem auto; max-width: 34rem; line-height: 1.5; color: #111; }}
    h1 {{ font-size: 1.6rem; margin-bottom: 0; }}
    p.sub {{ color: #666; margin-top: .25rem; }}
    table {{ border-collapse: collapse; width: 100%; margin-top: 1.5rem; }}
    th, td {{ text-align: left; padding: .4rem .6rem; border-bottom: 1px solid #eee; }}
    th {{ color: #666; font-weight: 500; width: 10rem; }}
    footer {{ margin-top: 2rem; color: #888; font-size: .85rem; }}
  </style>
</head>
<body>
  <h1>{info["app"]}</h1>
  <p class="sub">version {info["version"]} &middot; env {info["environment"]}</p>
  <table>{rows}</table>
  <footer>Agentic DevOps Sandbox &middot; local only &middot; no cloud access</footer>
</body>
</html>
"""
    )


@app.get("/healthz", response_class=PlainTextResponse, tags=["probes"])
async def healthz() -> PlainTextResponse:
    """Liveness. Always OK while the process can serve requests."""
    return PlainTextResponse("ok")


@app.get("/readyz", response_class=PlainTextResponse, tags=["probes"])
async def readyz() -> PlainTextResponse:
    """Readiness. 200 when the app should receive traffic, 503 otherwise."""
    if not _ready:
        return PlainTextResponse("not ready", status_code=status.HTTP_503_SERVICE_UNAVAILABLE)
    return PlainTextResponse("ready")


@app.get("/version", response_class=PlainTextResponse, tags=["meta"])
async def version() -> PlainTextResponse:
    """Just the version string — handy for scripting a deployment check."""
    return PlainTextResponse(settings.app_version)


@app.get("/api/info", tags=["meta"])
async def api_info() -> JSONResponse:
    """Machine-readable version of the status page."""
    return JSONResponse(_info())
