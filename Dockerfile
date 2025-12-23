FROM ubuntu:22.04

# =====================
# Base system
# =====================
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    ca-certificates \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# =====================
# Install Ollama
# =====================
RUN curl -fsSL https://ollama.com/install.sh | sh

# =====================
# Install Open WebUI
# =====================
RUN pip3 install --no-cache-dir open-webui

# =====================
# Ollama FULL THROTTLE
# =====================
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_NUM_THREADS=32
ENV OLLAMA_MAX_LOADED_MODELS=1
ENV OLLAMA_KEEP_ALIVE=10m

# =====================
# Preload MAX model
# =====================
RUN ollama serve & \
    sleep 12 && \
    ollama pull qwen2.5:14b && \
    pkill ollama

# =====================
# Supervisor configs
# =====================
RUN mkdir -p /etc/supervisor/conf.d

RUN cat <<'EOF' > /etc/supervisor/conf.d/ollama.conf
[program:ollama]
command=/usr/local/bin/ollama serve
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
EOF

RUN cat <<'EOF' > /etc/supervisor/conf.d/webui.conf
[program:webui]
command=python3 -m open_webui --host 0.0.0.0 --port 8080
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
EOF

# =====================
# Ports
# =====================
EXPOSE 8080 11434

# =====================
# Start services
# =====================
CMD ["/usr/bin/supervisord", "-n"]
