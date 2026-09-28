"""hello-devops: a deliberately small app whose job is to be observable.

It reports its own version, environment and hostname so that a Docker rebuild, a
Kubernetes rollout and an Argo CD sync are all *visible* in the browser.
"""

__all__ = ["__version__"]

__version__ = "0.1.0"
