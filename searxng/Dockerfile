# ============================================================
# WebSearch Stack — SearXNG metasearch engine
# ============================================================
# Single-stage build. Requires Tor service for DuckDuckGo
# and Startpage proxying via SOCKS5.

FROM searxng/searxng:latest

# Install SOCKS5 support (required for Tor proxy fallback)
RUN /usr/local/searxng/.venv/bin/python3 -m ensurepip --upgrade && \
    /usr/local/searxng/.venv/bin/python3 -m pip install --no-cache-dir socksio && \
    rm -rf /tmp/*

# Copy custom settings to a non-VOLUME path (base image has VOLUME /etc/searxng)
# which would hide our file at runtime.
COPY searxng/settings.yml /etc/searxng-custom/settings.yml
ENV SEARXNG_SETTINGS_PATH=/etc/searxng-custom/settings.yml
