FROM node:18-alpine AS base
WORKDIR /app

# Limpa cache do npm (opcional, mas recomendado)
RUN npm cache clean --force

FROM base AS deps
COPY package*.json ./

# Adicione este comando para remover o lock file e node_modules se existirem
# Isso força o npm a resolver as dependências do zero com as versões mais recentes.
RUN rm -f package-lock.json && rm -rf node_modules

# Instala as dependências
RUN if [ -f package-lock.json ]; then \
      npm ci --omit=dev --no-audit --prefer-offline; \
    else \
      npm install --omit=dev --no-audit; \
    fi

FROM base AS runner
WORKDIR /app

RUN apk add --no-cache curl
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs

COPY --from=deps /app/node_modules ./node_modules
COPY . .

USER nodejs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["npm", "start"]
