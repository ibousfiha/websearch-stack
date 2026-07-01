# WebSearch Stack

Self-hosted meta-search stack powered by **SearXNG**, with **Redis** caching, **Tor** privacy, and an optional **fastCRW** scraper sidecar.

## Architecture

```
                   ┌──────────────┐
                   │   Browser /  │
                   │    Client    │
                   └──────┬───────┘
                          │ :8080
          ┌───────────────┴─────────────────┐
          │          SearXNG                │
          │  (docker.io/searxng/searxng)    │
          └──┬──────┬──── ──┬───────┬───────┘
             │      │       │       │
        ┌────┘  ┌───┘    ┌──┘   ┌───┴────────┐
        ▼       ▼        ▼      ▼            │
   ┌────────┐ ┌─────┐ ┌────┐ ┌──────┐        │
   │ Redis  │ │ Tor │ │Goog│ │Brave │        │
   │(cache) │ │socks│ │ dir│ │ API  │        │
   └────────┘ └─────┘ └────┘ └──────┘        │
             ┌─────┐ ┌─────┐        ┌────────┴──┐
             │ DDG │ │Start│        │  fastCRW  │
             │onion│ │page │        │(scraper)  │
             └─────┘ └─────┘        └─────┬─────┘
                                    ┌────┴──────┐
                                    │ LightPanda│
                                    │(JS render)│
                                    └───────────┘
```

## Services

| Service | Image | Purpose |
|---|---|---|
| **SearXNG** | `searxng/searxng:latest` | Meta-search engine — queries upstream engines and aggregates results |
| **Redis** | `redis:8.8.0-alpine` | Shared cache (Valkey adapter) to reduce duplicate upstream requests |
| **Tor** | `sebastianalbers/tor:latest` | SOCKS5 proxy for DuckDuckGo (.onion) and Startpage (anti-CAPTCHA) |
| **fastCRW** | `ghcr.io/us/crw:latest` | Firecrawl-compatible Rust scraper (optional, port `:3000`) |
| **LightPanda** | `lightpanda/browser:latest` | Headless JS renderer sidecar for fastCRW |

## Prerequisites

- [Docker](https://docs.docker.com/engine/install/) with Compose V2
- `openssl` (for generating secrets)

## Quick Start

```bash
# 1. Clone the repo
git clone <repo-url> websearch-stack && cd websearch-stack

# 2. Configure secrets
cp env.template .env
# Generate a secure random secret:
echo "SEARXNG_SECRET=$(openssl rand -hex 32)" >> .env
# Set a Redis password (any alphanumeric string):
echo "REDIS_PASSWORD=$(openssl rand -hex 16)" >> .env

# 3. (Optional) Add a Brave Search API key
#    Get one free at https://api-dashboard.search.brave.com
#    Then uncomment BRAVE_API_KEY in .env

# 4. Start the stack
docker compose up -d

# 5. Open SearXNG
open http://localhost:8080

# 6. Check logs
docker compose logs -f
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `SEARXNG_SECRET` | Yes | Secret key for SearXNG sessions — generate with `openssl rand -hex 32` |
| `REDIS_PASSWORD` | Yes | Redis auth password |
| `BRAVE_API_KEY` | No | Brave Search API key — free credits at [api-dashboard.search.brave.com](https://api-dashboard.search.brave.com) |

Copy `env.template` to `.env` and fill in the values.

## Search Engines

| Engine | Type | Privacy | Notes |
|---|---|---|---|
| **Google** | Direct clearnet | — | No proxy, no retries |
| **DuckDuckGo** | Tor .onion | ✅ Full | Uses `.onion` hidden service to bypass DDG's clearnet Tor block |
| **DuckDuckGo** (images, videos, news) | Tor .onion | ✅ Full | Extra engine for media categories |
| **Startpage** | Tor SOCKS5 | ✅ Full | Tor exit nodes avoid CAPTCHA from datacenter IPs |
| **Brave** | HTML (direct) | — | Falls back if Brave API is unavailable |
| **Brave API** | Official API | — | Requires `BRAVE_API_KEY` — primary Brave source when configured |
| **Wikipedia** | Direct | — | |

## Zero-Suspension Policy

The stack never suspends engines on errors. Instead of waiting hours for a suspension to expire, it retries immediately on the next query. This means:

- **CAPTCHAs** — retried (Tor rotates IPs on restart)
- **Access denied / rate limits** — retried immediately
- **Cloudflare challenges** — retried

## Updating

Since all images use floating tags (`:latest`), simply run:

```bash
docker compose pull
docker compose up -d
```

## API Access

SearXNG exposes both HTML and JSON endpoints at `http://localhost:8080`:

```bash
# JSON API example
curl -X POST http://localhost:8080/search \
  -H "Content-Type: application/json" \
  -d '{"q": "hello world", "format": "json"}'
```

fastCRW exposes a Firecrawl-compatible API at `http://localhost:3000`:

```bash
# Scrape a page
curl http://localhost:3000/v1/scrape \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'

# Crawl
curl http://localhost:3000/v1/crawl \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'
```
