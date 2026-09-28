# docs/learning-notes/

Your space. The agent does not maintain this directory.

A suggestion that works well: after each phase, write down — in your own words,
without looking anything up — the three things you would struggle to explain to
someone else. Those gaps are the actual curriculum.

Prompts worth answering as you go:

**Phase 2 (Docker)** — Why does layer order matter for build caching? What
specifically does a multi-stage build leave behind? Why non-root?

**Phase 3 (Terraform / kind)** — What is in state, and why is it sensitive? What
does `plan` actually compare? Why can a kind node not see your local images?

**Phase 4 (Kubernetes)** — What is the difference between what liveness and
readiness failures cause? What does `maxUnavailable: 0` buy you? Requests vs
limits: which one does the scheduler use?

**Phase 5 (Argo CD)** — What exactly does "drift" mean? What happens when you
`kubectl edit` a synced resource, and why? What can `prune: true` delete that you
did not intend?

**Phase 6 (CI/CD)** — Why is a digest better than a tag? How does a promotion
loop form, and how is it broken?

**Phase 7 (AWS)** — Why is OIDC better than an access key? What is the smallest
IAM policy that would have let the pipeline work?
