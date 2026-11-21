# ADR 0001: shared Ollama and LLM integration ownership

- Status: accepted
- Date: 2026-11-21
- Context: `gogate`, `lmlog`, `ops-console`

## Context

`lmlog` and `gogate` used to be able to start their own Ollama container and call
it directly. That produced two containers, two model volumes, two `ollama pull`
runs and duplicated retry/timeout/metrics logic. `ops-console` should not know
about Ollama at all.

## Decision

1. **Ollama is shared external infrastructure.** The full stack starts it in
   `infra/docker-compose.yml`; port `11434` is not published to the host.
2. **`gogate` is the single owner of the LLM integration.** Providers, timeouts,
   retries, fallback, rate limits, cache, metrics, cost and audit live there.
3. **`lmlog` is a consumer.** By default (`LMLOG_LLM_MODE=gateway`) it calls
   `gogate` over the OpenAI-compatible API. Direct Ollama remains only in the
   standalone `direct` mode.
4. **`ops-console` never knows about Ollama.** It uses only `gogate` and `lmlog`.
5. **Standalone `ai` profiles** in `gogate` and `lmlog` are a development
   convenience, not ownership. They are mutually exclusive with the full stack.

## Consequences

- One Ollama container, one volume and one pull in the full stack.
- All LLM traffic goes through one gateway: limits, cost, traces and cache are
  visible in one place.
- If `gogate` or Ollama fails, `lmlog` falls back to deterministic heuristics;
  ingest/scan/trends keep working.
- There is a network dependency `lmlog → gogate`; it is intentional and covered
  by the fallback.
- Standalone development must explicitly use `LMLOG_LLM_MODE=direct` and must not
  run together with `infra/`.

## Alternatives

- **Keep Ollama in each repository.** Rejected: two containers, two volumes,
  duplicated logic and a port conflict.
- **Give `lmlog` its own LLM layer.** Rejected: blurs boundaries and duplicates
  retries/limits/metrics.
- **Make `ops-console` call Ollama.** Rejected: the console must not know about
  LLM infrastructure.
