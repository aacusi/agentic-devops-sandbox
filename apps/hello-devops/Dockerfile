# hello-devops container image.
#
# NOTHING HAS BEEN BUILT FROM THIS FILE YET — phase 2 does that, after review.
#
# Design choices worth understanding, because each one is a Kubernetes lesson:
#
#  * Multi-stage: build tooling (pip, compilers, caches) never reaches the final
#    image. Smaller image = faster `kind load` and fewer CVEs to triage.
#  * Non-root user: Kubernetes can enforce runAsNonRoot, and this image satisfies
#    it without a securityContext hack.
#  * Virtualenv copied wholesale: one COPY instead of re-resolving dependencies,
#    and dependency layers cache independently of source-code layers.
#  * APP_VERSION baked in at build time: a running container can always tell you
#    exactly which artifact it came from. This is what /version reports.
#
# Base image is pinned by tag here. Phase 2 pins it by digest (sha256:...) so a
# rebuild can never silently pick up a different base.

# --------------------------------------------------------------------------
# Stage 1: build the dependency set into a self-contained virtualenv
# --------------------------------------------------------------------------
FROM python:3.12-slim-bookworm AS builder

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /build

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy metadata first so dependency installation is cached independently of the
# application source. Editing main.py must not trigger a dependency reinstall.
COPY pyproject.toml README.md ./
COPY src/ ./src/

RUN pip install --upgrade pip setuptools wheel \
    && pip install .

# --------------------------------------------------------------------------
# Stage 2: minimal runtime
# --------------------------------------------------------------------------
FROM python:3.12-slim-bookworm AS runtime

ARG APP_VERSION=0.0.0-dev

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    APP_NAME=hello-devops \
    APP_VERSION=${APP_VERSION} \
    APP_ENV=docker \
    LOG_LEVEL=info

# System user with no shell and no home directory to write to.
RUN groupadd --system --gid 10001 app \
    && useradd --system --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app

COPY --from=builder /opt/venv /opt/venv

WORKDIR /app
USER 10001:10001

EXPOSE 8000

# Container-level healthcheck for `docker run` / compose. Kubernetes ignores this
# and uses the probes in the Deployment instead — keep the two consistent.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/healthz', timeout=2).status == 200 else 1)"]

# Single worker: in Kubernetes you scale with replicas, not with in-container
# workers, so that the scheduler can see and balance the load.
CMD ["uvicorn", "hello_devops.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
