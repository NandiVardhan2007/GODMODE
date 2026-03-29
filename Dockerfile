# G0DM0D3 Research Preview API
# Deploy on Hugging Face Spaces (Docker SDK) or any container host.
#
# Build:  docker build -t g0dm0d3-api .
# Run:    docker run -p 7860:7860 \
#           -e OPENROUTER_API_KEY=sk-or-... \
#           -e GODMODE_API_KEY=your-secret-key \
#           g0dm0d3-api
#
# OPENROUTER_API_KEY: Your OpenRouter key (powers all model calls)
# GODMODE_API_KEY:    Auth key callers must send as Bearer token
# HF_TOKEN:           HuggingFace write token for auto-publishing data
# HF_DATASET_REPO:    Target HF dataset repo (e.g. LYS10S/g0dm0d3-research)

FROM node:20-slim

# FIX 1: Install curl — node:20-slim ships without it, HEALTHCHECK crashes otherwise
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files and install production deps only
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev 2>/dev/null || npm install --omit=dev

# Copy source (api server + engine libs it imports)
COPY api/ ./api/
COPY src/lib/ ./src/lib/
COPY src/stm/ ./src/stm/

# Create non-root user for security
RUN addgroup --system app && adduser --system --ingroup app app

# FIX 2: Render injects PORT automatically (usually 10000). Server reads process.env.PORT.
ENV PORT=10000
EXPOSE 10000

# Switch to non-root user
USER app

# Health check — curl is now present
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s \
  CMD curl -f http://localhost:${PORT}/v1/health || exit 1

CMD ["npx", "tsx", "api/server.ts"]
