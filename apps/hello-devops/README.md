# hello-devops

A deliberately small FastAPI application. Its purpose is **not** to be interesting —
it is to be *observable*, so that every step of the delivery chain becomes visible.

It reports three things that change as it moves through the pipeline:

| Value | Laptop | Docker | Kubernetes |
|-------|--------|--------|------------|
| `environment` | `local` | `docker` | `kind` (from a ConfigMap) |
| `version` | from `pyproject.toml` | baked in at build time | from the image tag |
| `instance` | your hostname | container ID | **pod name** (downward API) |

Watching `instance` change while refreshing `/` is how you will confirm a rolling
update actually happened in phase 4, and how you will confirm Argo CD did it for
you in phase 5.

## Endpoints

| Path | Returns | Used by |
|------|---------|---------|
| `/` | HTML status page | you |
| `/healthz` | `ok` | Kubernetes liveness probe |
| `/readyz` | `ready` / 503 `not ready` | Kubernetes readiness probe |
| `/version` | version string | deployment verification scripts |
| `/api/info` | JSON with all fields | tests, debugging |
| `/docs` | OpenAPI UI (FastAPI default) | you |

## Run it

From the repository root:

```bash
make install
make run          # http://localhost:8000
make test
make lint
```

## Configuration

Environment variables only — no config files, no secret stores.

| Variable | Default | Set by |
|----------|---------|--------|
| `APP_NAME` | `hello-devops` | Dockerfile |
| `APP_VERSION` | package version | Docker build arg / manifest |
| `APP_ENV` | `local` | Makefile / Dockerfile / ConfigMap |
| `LOG_LEVEL` | `info` | ConfigMap |
| `POD_NAME` | empty | Kubernetes downward API |
| `NODE_NAME` | empty | Kubernetes downward API |

## Layout

```
apps/hello-devops/
├── pyproject.toml              deps, ruff and pytest config
├── Dockerfile                  multi-stage, non-root (built in phase 2)
├── .dockerignore
├── src/hello_devops/
│   ├── __init__.py             package version
│   ├── config.py               environment -> Settings dataclass
│   └── main.py                 FastAPI app, probes, status page
└── tests/test_main.py          endpoint + probe contract tests
```

## Why liveness and readiness are different

`/healthz` failing means "restart me". `/readyz` failing means "stop sending me
traffic, but leave me alone". Wiring a database check into the liveness probe is a
classic outage amplifier: the database blips, every pod fails liveness, Kubernetes
restarts the entire fleet at once. This app keeps the two strictly separate so the
Deployment in `k8s/` can demonstrate the correct pattern.
