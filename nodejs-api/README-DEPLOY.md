# CriptoSee API - Guia de Deploy VPS

Backend Node.js independente para substituir Supabase e rodar em VPS própria.

## 🚀 Características

- **API RESTful** para dados de criptomoedas
- **PostgreSQL** como banco de dados
- **CoinGecko API** para dados em tempo real
- **Cron jobs** para atualização automática a cada 30s
- **Docker** pronto para deploy
- **Nginx** com SSL configurado

## 📋 Pré-requisitos

- VPS com Ubuntu 20.04+ (mínimo 2GB RAM)
- Docker e Docker Compose
- PostgreSQL 13+
- Domínio próprio (opcional, para SSL)

## 🛠️ Instalação Rápida

### 1. Preparar VPS

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout/login para aplicar permissões Docker
```

### 2. Deploy Automático

```bash
# Clone o projeto
git clone <seu-repo>
cd nodejs-api

# Execute o script de deploy
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

O script vai:
- ✅ Verificar dependências
- ✅ Configurar PostgreSQL
- ✅ Criar banco e tabelas
- ✅ Fazer build da API
- ✅ Configurar Nginx
- ✅ Testar endpoints

### 3. Configuração Manual (alternativa)

```bash
# Configurar variáveis
cp .env.production .env
# Edite .env com suas configurações

# Criar banco
docker-compose -f docker-compose.production.yml up -d postgres
sleep 10

# Executar migrations
docker-compose -f docker-compose.production.yml exec postgres psql -U postgres -d criptosee -f /docker-entrypoint-initdb.d/setup-database.sql

# Iniciar API
docker-compose -f docker-compose.production.yml up -d
```

## ⚙️ Configuração

### Arquivo .env essencial

```env
# Database
DB_PASSWORD=SUA_SENHA_SUPER_SEGURA
DB_HOST=postgres
DB_NAME=criptosee

# API
FRONTEND_URL=https://seu-dominio.com
PORT=3000
NODE_ENV=production

# Performance
DB_MAX_CONNECTIONS=20
CRON_INTERVAL=30
```

### SSL com certificados próprios

```bash
# Criar diretório SSL
mkdir -p nginx/ssl

# Adicionar certificados
cp seu-certificado.crt nginx/ssl/cert.pem
cp sua-chave-privada.key nginx/ssl/key.pem

# Reiniciar Nginx
docker-compose -f docker-compose.production.yml restart nginx
```

### SSL com Let's Encrypt (Certbot)

```bash
# Instalar Certbot
sudo apt install certbot

# Obter certificado
sudo certbot certonly --standalone -d seu-dominio.com

# Copiar certificados
sudo cp /etc/letsencrypt/live/seu-dominio.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/seu-dominio.com/privkey.pem nginx/ssl/key.pem

# Renovação automática
sudo crontab -e
# Adicionar: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 📊 Endpoints da API

```bash
# Health check
curl https://sua-api.com/health

# Mercados (principais)
curl https://sua-api.com/api/markets

# Moedas específicas
curl https://sua-api.com/api/coins/bitcoin

# Estatísticas globais
curl https://sua-api.com/api/global

# Atualização manual
curl -X POST https://sua-api.com/api/refresh-markets
```

## 🔄 Conectar Frontend

### Opção 1: Substituir hook useCrypto

```typescript
// src/hooks/useCryptoAPI.ts
import { useState, useEffect } from 'react';

const API_BASE = 'https://sua-api.com/api';

export const useCryptoAPI = () => {
  const [cryptos, setCryptos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  const fetchCryptos = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE}/markets?limit=500`);
      
      if (!response.ok) {
        throw new Error(`API Error: ${response.status}`);
      }
      
      const result = await response.json();
      
      // Mapear para formato esperado pelo frontend
      const cryptos = result.data.map(item => ({
        id: item.coin_id,
        name: item.name || item.coin_id,
        symbol: item.symbol?.toLowerCase() || '',
        current_price: Number(item.price) || 0,
        price_change_percentage_24h: Number(item.price_change_percentage_24h) || 0,
        price_change_percentage_1h_in_currency: Number(item.price_change_percentage_1h) || 0,
        market_cap_rank: Number(item.market_cap_rank) || 0,
        image: item.image || '',
        market_cap: Number(item.market_cap) || 0,
        total_volume: Number(item.volume_24h) || 0,
      }));
      
      setCryptos(cryptos);
      setError(null);
    } catch (err) {
      console.error('Erro ao buscar dados:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCryptos();
    const interval = setInterval(fetchCryptos, 30000); // 30 segundos
    return () => clearInterval(interval);
  }, []);

  return {
    cryptos,
    loading,
    error,
    refetch: fetchCryptos
  };
};
```

### Opção 2: Modificar hook existente

```typescript
// src/hooks/useCrypto.ts
// Substituir fetchFromSupabase por fetchFromAPI

const fetchFromAPI = async () => {
  console.log('📡 Buscando dados da API...');
  
  const response = await fetch(`${API_BASE}/markets?limit=500`);
  
  if (!response.ok) {
    throw new Error(`API Error: ${response.status}`);
  }
  
  const result = await response.json();
  
  // Converter para formato CryptoData[]
  const cryptos = result.data.map(item => ({
    // ... mapeamento igual ao exemplo acima
  }));
  
  return { cryptos, globalData: calculateGlobalData(cryptos) };
};
```

## 🔧 Monitoramento & Manutenção

### Ver logs em tempo real

```bash
# Todos os serviços
docker-compose -f docker-compose.production.yml logs -f

# Apenas API
docker-compose -f docker-compose.production.yml logs -f criptosee-api

# Apenas PostgreSQL
docker-compose -f docker-compose.production.yml logs -f postgres
```

### Comandos úteis

```bash
# Status dos containers
docker-compose -f docker-compose.production.yml ps

# Restart completo
docker-compose -f docker-compose.production.yml restart

# Parar tudo
docker-compose -f docker-compose.production.yml down

# Backup do banco
docker-compose -f docker-compose.production.yml exec postgres pg_dump -U postgres criptosee > backup-$(date +%Y%m%d).sql

# Restaurar backup
docker-compose -f docker-compose.production.yml exec -T postgres psql -U postgres criptosee < backup.sql
```

### Monitoramento de performance

```bash
# CPU e memória dos containers
docker stats

# Espaço em disco
df -h

# Logs de sistema
journalctl -u docker -f
```

## 🔒 Segurança

### Firewall básico

```bash
# Configurar UFW
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw deny 5432  # PostgreSQL apenas interno
```

### Backup automático

```bash
# Criar script de backup
sudo nano /usr/local/bin/backup-criptosee.sh

#!/bin/bash
cd /path/to/nodejs-api
docker-compose -f docker-compose.production.yml exec -T postgres pg_dump -U postgres criptosee | gzip > /backups/criptosee-$(date +%Y%m%d-%H%M).sql.gz

# Manter apenas últimos 7 dias
find /backups -name "criptosee-*.sql.gz" -mtime +7 -delete

# Adicionar ao crontab
sudo crontab -e
# 0 2 * * * /usr/local/bin/backup-criptosee.sh
```

## 🚨 Troubleshooting

### API não responde

```bash
# Verificar status
curl -I http://localhost:3000/health

# Logs da API
docker-compose -f docker-compose.production.yml logs criptosee-api

# Restart da API
docker-compose -f docker-compose.production.yml restart criptosee-api
```

### Banco não conecta

```bash
# Verificar PostgreSQL
docker-compose -f docker-compose.production.yml exec postgres pg_isready -U postgres

# Logs do banco
docker-compose -f docker-compose.production.yml logs postgres

# Conectar manualmente
docker-compose -f docker-compose.production.yml exec postgres psql -U postgres -d criptosee
```

### Performance lenta

```bash
# Verificar índices
docker-compose -f docker-compose.production.yml exec postgres psql -U postgres -d criptosee -c "\di"

# Verificar tamanho das tabelas
docker-compose -f docker-compose.production.yml exec postgres psql -U postgres -d criptosee -c "SELECT schemaname,tablename,pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) FROM pg_tables WHERE schemaname='public';"

# Limpar histórico antigo
docker-compose -f docker-compose.production.yml exec postgres psql -U postgres -d criptosee -c "SELECT public.cleanup_old_history();"
```

## 📈 Próximos Passos

1. **Deploy inicial**: Execute o script de deploy
2. **Teste endpoints**: Verifique se API responde
3. **Configure domínio**: Aponte DNS para sua VPS
4. **SSL**: Configure certificados HTTPS
5. **Frontend**: Atualize URLs no frontend
6. **Backup**: Configure rotina de backup
7. **Monitoramento**: Configure alerts

---

**🎉 Resultado**: API Node.js rodando independente do Supabase na sua VPS!