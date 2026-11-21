# Contributing

This is a portfolio project, but it is maintained like a real service.

## Local checks

```bash
make config
make up
make smoke
make smoke-fallback
```

Individual repositories:

```bash
(cd ../gogate && make test && make lint)
(cd ../lmlog && make test && make lint)
(cd ../ops-console && npm test && npm run typecheck && npm run lint)
(cd ../ledger && make test && make vet)
```

## Rules

- Do not commit `.env`, `.secrets/`, generated keys, logs or screenshots with
  real customer data.
- Keep AI-generated changes behind tests and review.
- Document architectural decisions in ADRs.
- Update `CHANGELOG.md` for user-visible changes.
- Use conventional commit prefixes (`feat:`, `fix:`, `docs:`, `ci:`).

See [AI_WORKFLOW.md](AI_WORKFLOW.md) for the AI-assisted workflow.
