# Probes: values chosen and why
| Probe | Setting | Reason |
|---|---|---|
| startup | every 2s, 30 failures (60s) | Slow starts and Key Vault secret mount must not trigger restarts; liveness/readiness are disabled until startup passes |
| readiness | every 5s, timeout 2s, 3 failures | Stops traffic quickly during overload or dependency issues, no restart |
| liveness | every 10s, timeout 2s, 3 failures | Restart only on true deadlock; keep it cheap and do NOT check downstream dependencies |
Common mistakes: liveness hitting the database (cascading restarts), no startupProbe with aggressive liveness (restart loops), identical readiness and liveness, timeouts of 1s under CPU throttling, probing a path needing auth.
