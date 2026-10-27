# Anki (headless) on Kubernetes

Runs a headless, AnkiConnect-compatible HTTP API in a pod and keeps the
collection synced with **AnkiWeb**. AnkiWeb stays the source of truth; your
desktop/mobile clients keep syncing to AnkiWeb as normal and this pod is just
another sync client that also serves an API.

Image: [`glechic/anki-connect-server`](https://github.com/glechic/anki-connect-server)
— a FastAPI server over the official `anki` library (no Qt/Xvfb/KasmVNC). It
speaks the AnkiConnect JSON protocol on `POST /` and `POST /api`, and exposes
`GET /health`. It is `arm64`-native, so it runs on this cluster's Ampere nodes
with no emulation.

## What this deploys

| File | Resource | Notes |
| --- | --- | --- |
| `kubernetes/secrets/anki.yaml` | `Secret anki-secret` | AnkiWeb credentials (`ANKI_USERNAME`, `ANKI_PASSWORD`). Fill in / apply manually. |
| `kubernetes/deployments/anki.yaml` | `Deployment anki-deployment` | `replicas: 1`, `Recreate`, **no volume** (`emptyDir /data`, ephemeral). |
| `kubernetes/services/anki.yaml` | `Service anki-service` | ClusterIP; `8765` (AnkiConnect). |
| `kubernetes/configmaps/anki-proxy.yaml` | `ConfigMap anki-proxy-config` | nginx `default.conf` (auth + reverse proxy). |
| `kubernetes/secrets/anki-proxy-auth.yaml` | `Secret anki-proxy-auth` | `.htpasswd` for nginx basic auth. Fill in / apply manually. |
| `kubernetes/deployments/anki-proxy.yaml` | `Deployment anki-proxy-deployment` | `nginx:alpine`; only public entry to AnkiConnect. |
| `kubernetes/services/anki-proxy.yaml` | `Service anki-proxy-service` | ClusterIP:80; the tunnel target. |
| `kubernetes/netpol/anki.yaml` | `NetworkPolicy anki-allow-proxy-only` | Best-effort: `8765` only from the proxy. |

There is deliberately **no PersistentVolumeClaim**. The collection lives on an
`emptyDir` and is rebuilt from AnkiWeb on every restart (see below).

Networking is private by default: `anki-service` is ClusterIP and nothing routes
to it. The only path in is `anki-proxy-service` (nginx, HTTP Basic Auth), which
the cloudflared tunnel fronts at `anki-api.allistergrange.com`.

## Sync model

`anki-connect-server` does **not** auto-sync on a timer (unlike the previous
desktop image). Syncing is driven in two places:

1. **On start** — a `bootstrap-sync` sidecar waits for the API, then calls
   `{"action":"sync"}` once. Because `/data` is empty on every boot, this
   resolves to a **full download** from AnkiWeb (`FULL_DOWNLOAD`; the server
   disables full uploads by policy). This is what makes "re-download on
   restart" automatic. Watch it with
   `kubectl logs deploy/anki-deployment -c bootstrap-sync`.
2. **After writes** — the site backend must call `{"action":"sync"}` after each
   `addNote`/`updateNote` so cards reach AnkiWeb promptly. Anything added on the
   pod but not yet synced is lost on restart.

Credentials come from the env (`ANKICONNECT_ANKIWEB_USER`/`_PASS`, mapped from
`anki-secret`), so sync calls don't need to pass them.

## Applying

```bash
kubectl config use-context context-c4jljqtlzdq

# 1. credentials (edit the placeholders first, or create the secret out-of-band)
kubectl apply -f kubernetes/secrets/anki.yaml
kubectl apply -f kubernetes/secrets/anki-proxy-auth.yaml

# 2. app + proxy
kubectl apply -f kubernetes/deployments/anki.yaml
kubectl apply -f kubernetes/services/anki.yaml
kubectl apply -f kubernetes/configmaps/anki-proxy.yaml
kubectl apply -f kubernetes/deployments/anki-proxy.yaml
kubectl apply -f kubernetes/services/anki-proxy.yaml
kubectl apply -f kubernetes/netpol/anki.yaml

kubectl rollout status deploy/anki-deployment
kubectl logs deploy/anki-deployment | grep 'bootstrap sync'   # watch the pull
```

## Protecting the API (nginx + HTTP Basic Auth)

AnkiConnect (8765) has no authentication of its own, so it stays ClusterIP-only
and is fronted by a dedicated nginx pod that enforces **HTTP Basic Auth** on
every request:

```
cloudflared ─▶ anki-proxy-service:80 (nginx, auth_basic) ─▶ anki-service:8765
```

Create the credentials out-of-band so no real password lands in git.

> **Hashing note.** This deployment's `nginx:alpine` verifies **bcrypt**
> (`htpasswd -B`, `$2y$`) fine — its musl `crypt()` supports it (verified
> end-to-end). Upstream nginx built against glibc does not, so if you swap the
> proxy image to a glibc-based nginx, use apr1 (`htpasswd -c`, no `-B`) instead.
> Watch shell expansion of `$`/`!` in the password: quote it (`"$PW"`). A
> mismatch surfaces as a 401 with `password mismatch` in the nginx log.

```bash
read -s -p 'Password: ' PW; echo
htpasswd -nbB anki "$PW" > ./htpasswd   # bcrypt; fine on nginx:alpine
kubectl create secret generic anki-proxy-auth \
  --from-file=.htpasswd=./htpasswd \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart deploy/anki-proxy-deployment
```

## Testing the API (behind the auth)

AnkiConnect is private, so exercise it through the proxy. Easiest is a
port-forward to the proxy, then authenticate with `-u`:

```bash
# 1. forward the proxy locally
kubectl port-forward svc/anki-proxy-service 8080:80 &

# 2. list your decks (this is the money shot) -- should print your real decks
curl -s -u anki:the-password -H 'Content-Type: application/json' \
  http://localhost:8080/ \
  -d '{"action":"deckNames","version":6}'
# -> {"result":["Default","French",...],"error":null}

# 3. no credentials -> 401
curl -s -o /dev/null -w 'HTTP %{http_code}\n' \
  -H 'Content-Type: application/json' \
  http://localhost:8080/ -d '{"action":"version","version":6}'
# -> HTTP 401

# 4. sanity checks
curl -s -u anki:the-password -H 'Content-Type: application/json' \
  http://localhost:8080/ -d '{"action":"version","version":6}'
curl -s -u anki:the-password -H 'Content-Type: application/json' \
  http://localhost:8080/ -d '{"action":"sync","version":6}'

# 5. add a card, push it, then confirm it on ankiweb.net
curl -s -u anki:the-password -H 'Content-Type: application/json' \
  http://localhost:8080/ -d '{
    "action":"addNote","version":6,
    "params":{"note":{
      "deckName":"Default","modelName":"Basic",
      "fields":{"Front":"bonjour","Back":"hello"},"tags":["test"]
    }}
  }'
```

The same calls work against the public hostname once the tunnel route exists
(replace `http://localhost:8080/` with `https://anki-api.allistergrange.com/`).

## Cloudflare (cloudflared) hookup

The tunnel fronts the nginx proxy (never AnkiConnect directly):

```yaml
      - hostname: anki-api.allistergrange.com
        service: http://anki-proxy-service:80
```

After editing the ConfigMap, restart cloudflared and make sure the DNS route
exists:

```bash
kubectl rollout restart deploy/cloudflared
cloudflared tunnel route dns oke-primary-syd anki-api.allistergrange.com
```

Strongly recommended: front the public hostname with **Cloudflare Access**
(Zero Trust) as a second layer beyond the nginx basic auth.

## Caveats / design notes

- **Ephemeral storage:** no volume, so the collection is re-downloaded from
  AnkiWeb on every pod start (via the `bootstrap-sync` sidecar). Anything added
  on the pod but not yet synced is lost on restart; the backend must call
  `sync` after each write to keep that window small.
- **Single writer:** keep `replicas: 1`. The collection is a single-writer
  SQLite database; a second pod would boot an empty collection and fight over
  AnkiWeb.
- **Full-sync direction:** on an empty collection the server performs a full
  **download** (AnkiWeb is canonical) and refuses full uploads, so pod-only data
  can never overwrite AnkiWeb.
- **API surface:** this server implements the common AnkiConnect v6 actions
  (notes, cards, tags, decks, models, media, sync). Some desktop-oriented
  actions are absent (e.g. `bury`, `setFlag`, `setDueDate`, `forgetCards`,
  filtered decks, FSRS memory-state, review-session actions).
- **Resources:** ~50m/256Mi request, 512Mi limit.
