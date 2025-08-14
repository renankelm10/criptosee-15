-- Setup script para banco PostgreSQL - CriptoSee API
-- Execute este script depois de criar o banco 'criptosee'

-- Conecte ao banco: psql -U postgres -d criptosee -f scripts/setup-database.sql

\echo '=== Criando banco CriptoSee ==='

-- Criar schema se não existir
CREATE SCHEMA IF NOT EXISTS public;

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

\echo '=== Criando tabelas ==='

-- Tabela de moedas
CREATE TABLE IF NOT EXISTS public.coins (
    id TEXT PRIMARY KEY,
    symbol TEXT NOT NULL,
    name TEXT NOT NULL,
    image TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabela de dados atuais do mercado
CREATE TABLE IF NOT EXISTS public.latest_markets (
    coin_id TEXT PRIMARY KEY,
    price NUMERIC NOT NULL,
    market_cap NUMERIC,
    market_cap_rank INTEGER,
    volume_24h NUMERIC,
    price_change_percentage_1h NUMERIC,
    price_change_percentage_24h NUMERIC,
    price_change_percentage_7d NUMERIC,
    circulating_supply NUMERIC,
    total_supply NUMERIC,
    max_supply NUMERIC,
    ath NUMERIC,
    ath_change_percentage NUMERIC,
    ath_date TIMESTAMP WITH TIME ZONE,
    atl NUMERIC,
    atl_change_percentage NUMERIC,
    atl_date TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabela de histórico de preços
CREATE TABLE IF NOT EXISTS public.markets_history (
    id BIGSERIAL PRIMARY KEY,
    coin_id TEXT NOT NULL,
    price NUMERIC NOT NULL,
    market_cap NUMERIC,
    volume_24h NUMERIC,
    price_change_percentage_1h NUMERIC,
    price_change_percentage_24h NUMERIC,
    price_change_percentage_7d NUMERIC,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

\echo '=== Criando índices para performance ==='

-- Índices para otimizar consultas
CREATE INDEX IF NOT EXISTS idx_coins_symbol ON public.coins(symbol);
CREATE INDEX IF NOT EXISTS idx_coins_name ON public.coins(name);

CREATE INDEX IF NOT EXISTS idx_latest_markets_rank ON public.latest_markets(market_cap_rank) WHERE market_cap_rank IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_latest_markets_price_change_24h ON public.latest_markets(price_change_percentage_24h) WHERE price_change_percentage_24h IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_markets_history_coin_id ON public.markets_history(coin_id);
CREATE INDEX IF NOT EXISTS idx_markets_history_timestamp ON public.markets_history(timestamp);
CREATE INDEX IF NOT EXISTS idx_markets_history_coin_timestamp ON public.markets_history(coin_id, timestamp);

\echo '=== Criando função para atualizar updated_at ==='

-- Função para atualizar timestamp automaticamente
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para atualizar updated_at automaticamente
DROP TRIGGER IF EXISTS update_coins_updated_at ON public.coins;
CREATE TRIGGER update_coins_updated_at
    BEFORE UPDATE ON public.coins
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_latest_markets_updated_at ON public.latest_markets;
CREATE TRIGGER update_latest_markets_updated_at
    BEFORE UPDATE ON public.latest_markets
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

\echo '=== Criando função para limpeza de histórico antigo ==='

-- Função para limpar histórico antigo (manter apenas 30 dias)
CREATE OR REPLACE FUNCTION public.cleanup_old_history()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.markets_history 
    WHERE timestamp < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

\echo '=== Verificando estrutura ==='

-- Verificar se as tabelas foram criadas
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('coins', 'latest_markets', 'markets_history')
ORDER BY tablename;

\echo '=== Setup completo! ==='
\echo 'Próximos passos:'
\echo '1. Configure o arquivo .env com suas credenciais'
\echo '2. Execute: npm start'
\echo '3. Teste: curl http://localhost:3000/health'
\echo '4. Primeira atualização: curl -X POST http://localhost:3000/api/refresh-markets'