# Demo recording plan

Target length: 3–5 minutes. Record on a clean local machine, 1080p, with
sanitized sample logs. Never show `.env`, API keys, bearer tokens or private
hostnames.

## Before recording

```bash
cd ai-ops-stack
make down
make reset          # optional: removes volumes and re-creates .env
make up
make smoke
```

Close unrelated browser tabs and terminal history.

## Shot list

1. **Intro (10 s)** — `ai-ops-stack` README and architecture diagram.
2. **Startup (30–45 s)** — `make up`, show healthy containers and URLs.
3. **Dashboard (30 s)** — traffic, latency, errors, tokens, cache hit; open Grafana.
4. **Playground (45 s)** — streaming prompt, provider/fallback metadata, usage/cost.
5. **Compare (20 s)** — two models side by side.
6. **Logs (60 s)** — upload sanitized sample, watch SSE progress, open signatures,
   explain a cluster and ask a grounded question.
7. **Requests and traces (30 s)** — audit filters, span waterfall, Jaeger link.
8. **Fallback (30 s)** — `make smoke-fallback`, show `source=heuristic`, restore
   `gogate` with `docker compose start gogate`.
9. **Ledger (30 s)** — `cd ../ledger && make up`, dashboard and a transfer demo.
10. **Outro (10 s)** — links to the five repositories and v0.1.0 status.

## Output

- `docs/demo.mp4` — compressed 1080p, preferably under 50 MB;
- `docs/demo-poster.jpg` — poster for the README;
- optional `docs/demo.gif` — 10–15 second highlight.

If the MP4 is hosted externally, keep a stable unlisted URL in the README and
commit only the poster + link.
