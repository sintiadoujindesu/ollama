FROM ubuntu:22.04

# =====================
# Base system
# =====================
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3.11 \
    python3.11-venv \
    python3.11-distutils \
    ca-certificates \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
RUN python3.11 -m venv /env
ENV PATH="/env/bin:$PATH"

# Install pip and Open WebUI
RUN pip install --upgrade pip
RUN pip install open-webui

# =====================
# Install Ollama
# =====================
RUN curl -fsSL https://ollama.com/install.sh | sh

# =====================
# Environment Variables
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

# Ollama config
RUN cat << 'EOF' > /etc/supervisor/conf.d/ollama.conf
[program:ollama]
command=/usr/local/bin/ollama serve
autostart=true
autorestart=true
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
EOF

# Open WebUI config - ensure it's using the correct Python environment
RUN cat << 'EOF' > /etc/supervisor/conf.d/webui.conf
[program:webui]
command=/env/bin/open-webui serve --host 0.0.0.0 --port 8080
autostart=true
autorestart=true
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
EOF

# =====================
# Expose Ports
# =====================
EXPOSE 8080 11434

# =====================
# Start Supervisor
# =====================
CMD ["/usr/bin/supervisord", "-n"]
