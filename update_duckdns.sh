#!/bin/bash
# Script 12: Atualizacao Dinamica do IP para DuckDNS (Interativo)
# Solicita o token de autenticacao DuckDNS e a password do root do MariaDB.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
LOGFILE="/var/log/duckdns_update.log"

echo -e "${YELLOW}--- CONFIGURAÇÃO INTERATIVA DO DUCKDNS E SERVIÇOS ---${NC}"

# --- 1. SOLICITAR CREDENCIAIS CRÍTICAS ---
echo -e "\n${GREEN}--> Por favor, forneça as credenciais necessárias para a automação.${NC}"
read -sp "Token de Autenticação DuckDNS: " TOKEN
echo
read -sp "Password do Utilizador ROOT do MariaDB (para my.cnf): " DB_ROOT_PASS
echo
DOMAIN="sabordomar" # Seu domínio DuckDNS

if [ -z "$TOKEN" ] || [ -z "$DB_ROOT_PASS" ]; then
    echo -e "\n\033[0;31m❌ ERRO: Token ou Password não podem ser vazios. Abortando.${NC}"
    exit 1
fi

# --- 2. CONFIGURAR AUTENTICAÇÃO DO BACKUP (Requisito do Capítulo 6) ---
echo -e "\n${YELLOW}--> Criando ficheiro de autenticação segura do MariaDB (/root/.my.cnf)...${NC}"
MY_CNF_FILE="/root/.my.cnf"

sudo bash -c "cat > $MY_CNF_FILE" <<EOL
[mysqldump]
user=root
password="${DB_ROOT_PASS}"
EOL

sudo chmod 600 $MY_CNF_FILE
echo -e "${GREEN}✅ Ficheiro de autenticação de backup criado com sucesso.${NC}"

# --- 3. CRIAR O SCRIPT DE ATUALIZAÇÃO DUCKDNS ---
echo -e "\n${YELLOW}--> Criando script de atualização de IP (update_duckdns.sh)...${NC}"
SCRIPT_PATH="/usr/local/bin/update_duckdns.sh"

sudo bash -c "cat > $SCRIPT_PATH" <<EOL
#!/bin/bash
# Script agendado para atualizar o IP no DuckDNS a cada 5 minutos.
DOMAIN_NAME="${DOMAIN}"
DUCKDNS_TOKEN="${TOKEN}"
LOG_FILE="${LOGFILE}"
DATA=$(date "+%Y-%m-%d %H:%M:%S")

RESPONSE=\$(curl -s "https://www.duckdns.org/update?domains=\${DOMAIN_NAME}&token=\${DUCKDNS_TOKEN}&ip=")
    
if echo "\$RESPONSE" | grep "OK" > /dev/null; then
    STATUS="OK"
else
    STATUS="FALHA"
fi

echo "\${DATA} - Status: \${STATUS} | Resposta: \${RESPONSE}" >> \$LOG_FILE
EOL

sudo chmod +x $SCRIPT_PATH
echo -e "${GREEN}✅ Script de atualização de IP criado e executável.${NC}"

# --- 4. AGENDAR A TAREFA NO CRONTAB ---
echo -e "\n${YELLOW}--> Agendando a tarefa no crontab para rodar a cada 5 minutos...${NC}"
(sudo crontab -l 2>/dev/null | grep -v 'update_duckdns.sh'; echo "*/5 * * * * ${SCRIPT_PATH} >/dev/null 2>&1") | sudo crontab -

echo -e "${GREEN}=====================================================${NC}"
echo -e "${GREEN}Automação DuckDNS e Autenticação de Backup configuradas!${NC}"
echo -e "O log de atualização está em: ${LOGFILE}"
echo -e "${GREEN}=====================================================${NC}"