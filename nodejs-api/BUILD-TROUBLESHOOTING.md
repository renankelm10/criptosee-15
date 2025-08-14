# Troubleshooting Build - CriptoSee API

## ❌ Erro: npm ci requires package-lock.json

### Problema
```
npm error The `npm ci` command can only install with an existing package-lock.json
```

### Solução Implementada ✅

1. **package-lock.json criado** - Agora existe o arquivo necessário
2. **Dockerfile atualizado** - Usa `npm install` como fallback se não houver lock file

### Testando o Build

```bash
# Build local
cd nodejs-api
docker build -t criptosee-api .

# Ou com Docker Compose
docker-compose -f docker-compose.production.yml build
```

## 🔧 Outras Soluções Possíveis

### Opção 1: Regenerar package-lock.json

```bash
cd nodejs-api
rm -f package-lock.json
npm install
```

### Opção 2: Usar apenas npm install no Dockerfile

```dockerfile
# Em vez de npm ci
RUN npm install --omit=dev --no-audit
```

### Opção 3: Build sem cache

```bash
docker build --no-cache -t criptosee-api .
```

## 🐳 Docker Build Completo

```bash
# Limpar builds anteriores
docker system prune -f

# Build da imagem
cd nodejs-api
docker build -t criptosee-api .

# Testar container
docker run --rm -p 3000:3000 \
  -e DB_HOST=host.docker.internal \
  -e DB_PASSWORD=test \
  criptosee-api

# Verificar se está funcionando
curl http://localhost:3000/health
```

## 📋 Verificar Dependências

```bash
# Verificar se todas as dependências estão no package.json
cd nodejs-api
npm ls

# Atualizar dependências se necessário
npm update
```

## 🔍 Debug do Container

```bash
# Entrar no container para debug
docker run -it --entrypoint sh criptosee-api

# Verificar arquivos
ls -la
cat package.json
```

## ✅ Status Atual

- ✅ package-lock.json criado
- ✅ Dockerfile corrigido para lidar com ausência de lock file
- ✅ Build deve funcionar agora
- ✅ Mantém compatibilidade com npm ci quando possível

## 🚀 Deploy Após Correção

```bash
# Executar deploy
cd nodejs-api
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

O script de deploy agora deve funcionar sem erros de build!