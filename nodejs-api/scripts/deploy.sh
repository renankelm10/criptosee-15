#!/bin/bash

# Script de deploy para VPS - CriptoSee API
# Execute: chmod +x scripts/deploy.sh && ./scripts/deploy.sh

set -e

echo "🚀 Iniciando deploy da CriptoSee API..."

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não encontrado. Instalando..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker instalado. Faça logout/login e execute novamente."
    exit 1
fi

# Verificar se Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose não encontrado. Instalando..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

echo "📋 Verificando arquivos necessários..."

# Verificar se arquivo .env existe
if [ ! -f .env ]; then
    echo "⚠️  Arquivo .env não encontrado. Criando a partir do template..."
    cp .env.production .env
    echo "✏️  Configure o arquivo .env com suas credenciais e execute novamente."
    echo "📝 Principais configurações:"
    echo "   - DB_PASSWORD=sua_senha_segura"
    echo "   - FRONTEND_URL=https://seu-dominio.com"
    exit 1
fi

# Verificar se certificados SSL existem (opcional)
if [ ! -d "nginx/ssl" ]; then
    echo "⚠️  Certificados SSL não encontrados. Criando diretório..."
    mkdir -p nginx/ssl
    echo "📝 Para SSL, adicione cert.pem e key.pem em nginx/ssl/"
fi

echo "🔨 Fazendo build da aplicação..."

# Parar containers existentes
docker-compose -f docker-compose.production.yml down

# Build da imagem
docker-compose -f docker-compose.production.yml build --no-cache

echo "🗄️  Iniciando banco de dados..."

# Iniciar apenas o PostgreSQL primeiro
docker-compose -f docker-compose.production.yml up -d postgres

# Aguardar PostgreSQL ficar pronto
echo "⏳ Aguardando PostgreSQL inicializar..."
sleep 10

# Verificar se banco está funcionando
until docker-compose -f docker-compose.production.yml exec postgres pg_isready -U postgres -d criptosee; do
    echo "⏳ Aguardando PostgreSQL..."
    sleep 2
done

echo "✅ PostgreSQL está pronto!"

echo "🚀 Iniciando API..."

# Iniciar todos os serviços
docker-compose -f docker-compose.production.yml up -d

echo "⏳ Aguardando API inicializar..."
sleep 10

# Testar health check
echo "🔍 Testando API..."
if curl -f http://localhost:3000/health; then
    echo "✅ API está funcionando!"
else
    echo "❌ API não está respondendo. Verificando logs..."
    docker-compose -f docker-compose.production.yml logs criptosee-api
    exit 1
fi

echo "📊 Fazendo primeira atualização dos dados..."
curl -X POST http://localhost:3000/api/refresh-markets || echo "⚠️  Primeira atualização falhou, mas é normal."

echo ""
echo "🎉 Deploy concluído com sucesso!"
echo ""
echo "📋 Informações do deploy:"
echo "   🌐 API: http://localhost:3000"
echo "   ❤️  Health: http://localhost:3000/health" 
echo "   📊 Markets: http://localhost:3000/api/markets"
echo "   📈 Stats: http://localhost:3000/api/stats"
echo ""
echo "📝 Como conectar o frontend:"
echo "   1. Substituir useCrypto por useCryptoAPI (ver README-DEPLOY.md)"
echo "   2. Ou modificar API_BASE em useCrypto para 'http://SEU_IP:3000/api'"
echo ""
echo "📝 Próximos passos:"
echo "   1. Configure seu domínio/DNS para apontar para este servidor"
echo "   2. Configure certificados SSL em nginx/ssl/"
echo "   3. Atualize FRONTEND_URL no .env com seu domínio"
echo "   4. Configure backup do PostgreSQL"
echo ""
echo "🔧 Comandos úteis:"
echo "   📋 Ver logs: docker-compose -f docker-compose.production.yml logs -f"
echo "   🔄 Restart: docker-compose -f docker-compose.production.yml restart"
echo "   🛑 Parar: docker-compose -f docker-compose.production.yml down"
echo "   📊 Status: docker-compose -f docker-compose.production.yml ps"