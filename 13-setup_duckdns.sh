#!/bin/bash

# =================================================================
# Script 13: Configuração do Cliente DuckDNS
# Objetivo: Automatizar a atualização de um domínio DuckDNS via cron.
# =================================================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}--- CONFIGURANDO ATUALIZAÇÃO AUTOMÁTICA DO DUCKDNS ---${NC}"

# --- 1. VALIDAÇÃO DOS PARÂMETROS ---
DOMAIN_NAME=$1
if [ -z "$DOMAIN_NAME" ]; then
    echo -e "${RED}ERRO: O nome do domínio não foi fornecido a este script.${NC}"
    exit 1
fi

# Extrai apenas o subdomínio (ex: 'sabordomar' de 'sabordomar.duckdns.org')
SUBDOMAIN=$(echo "$DOMAIN_NAME" | cut -d. -f1)

# --- 2. SOLICITAR TOKEN ---
read -p "Por favor, introduza o seu Token do DuckDNS: " DUCKDNS_TOKEN
if [ -z "$DUCKDNS_TOKEN" ]; then
    echo -e "${RED}ERRO: O Token do DuckDNS é obrigatório. Abortando.${NC}"
    exit 1
fi

# --- 3. CRIAR DIRETÓRIO E SCRIPT DE ATUALIZAÇÃO ---
echo -e "\n${GREEN}--> Criando script de atualização em /opt/duckdns/update.sh...${NC}"
sudo mkdir -p /opt/duckdns

sudo bash -c "cat > /opt/duckdns/update.sh" <<EOL
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=${SUBDOMAIN}&token=${DUCKDNS_TOKEN}&ip=" | curl -k -o /opt/duckdns/duck.log -K -
EOL

sudo chmod 700 /opt/duckdns/update.sh

# --- 4. CONFIGURAR O CRON JOB ---
echo -e "${GREEN}--> Configurando tarefa no cron para executar a cada 5 minutos...${NC}"

sudo bash -c "cat > /etc/cron.d/duckdns" <<EOL
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
*/5 * * * * root /opt/duckdns/update.sh >/dev/null 2>&1
EOL

echo -e "\n${GREEN}--> Testando a execução inicial do script...${NC}"
sudo /opt/duckdns/update.sh

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Configuração do DuckDNS concluída com sucesso!${NC}"
echo -e "O seu IP será verificado e atualizado a cada 5 minutos."
echo -e "Verifique o log da última execução em: ${YELLOW}/opt/duckdns/duck.log${NC}"
echo -e "${GREEN}=====================================================${NC}"