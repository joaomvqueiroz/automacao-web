#!/bin/bash
# Script 12: Instalacao e Configuracao Interativa do Certificado SSL Let's Encrypt
# Objetivo: Solicitar dados do utilizador para automatizar o Certbot.

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}--- INICIANDO CONFIGURAÇÃO DE SSL COM CERTBOT (Let's Encrypt) ---${NC}"

# --- 1. VALIDAÇÃO DOS PARÂMETROS RECEBIDOS ---
DOMAIN=$1
EMAIL=$2

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo -e "${RED}ERRO: O Domínio e o Email são obrigatórios e não foram passados para o script.${NC}"
    exit 1
fi

# --- 3. INSTALAÇÃO DO CERTBOT ---
echo -e "\n${YELLOW}--> Verificando/Instalando Certbot e o plugin Apache...${NC}"
# Instala o Certbot (Assumindo que o EPEL ja esta ativo, conforme os scripts anteriores)
sudo dnf install -y certbot python3-certbot-apache
if [ $? -ne 0 ]; then
    echo -e "${RED}ERRO: Falha ao instalar o Certbot. Verifique os repositorios.${NC}"
    exit 1
fi

# --- 4. PREPARAÇÃO DO APACHE ---
echo -e "\n${YELLOW}--> Preparando o Apache para a configuração SSL...${NC}"
SSL_CONF_FILE="/etc/httpd/conf.d/ssl.conf"
if [ -f "$SSL_CONF_FILE" ]; then
    echo -e "${GREEN}--> Desativando a configuração SSL padrão para evitar conflitos...${NC}"
    sudo mv "$SSL_CONF_FILE" "${SSL_CONF_FILE}.disabled"
fi

# Testa a sintaxe do Apache antes de prosseguir
if ! sudo apachectl configtest; then
    echo -e "${RED}ERRO: A configuração do Apache contém erros mesmo após desativar o ssl.conf. Abortando.${NC}"
    exit 1
fi

# --- 5. OBTENÇÃO E INSTALAÇÃO DO CERTIFICADO ---
echo -e "\n${YELLOW}--> Solicitando certificado para ${DOMAIN}...${NC}"

# Executa o Certbot de forma nao interativa com todos os dominios necessarios
# Nota: Adicionamos o subdominio 'www' para cobertura maxima
# O Certbot irá perguntar sobre o redirecionamento interativamente na primeira vez
sudo certbot --apache \
    --non-interactive --agree-tos --redirect \
    -m "${EMAIL}" \
    -d "${DOMAIN}" \
    -d "www.${DOMAIN}"

if [ $? -ne 0 ]; then
    echo -e "${RED}ERRO: Falha ao obter o certificado SSL.${NC}"
    echo -e "Verifique se a Porta 80 esta aberta e redirecionada para este servidor."
    exit 1
fi

# --- 6. VERIFICAÇÃO DA RENOVAÇÃO AUTOMÁTICA ---
echo -e "\n${GREEN}--> Verificando o agendamento da renovação automática...${NC}"
# O Certbot instala um timer (systemd) ou cronjob para renovar automaticamente
sudo systemctl list-timers | grep 'certbot\|snap.certbot.renew'

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Certificado SSL de produção instalado e configurado com sucesso!${NC}"
echo -e "A renovação automatica foi agendada."
echo -e "${YELLOW}Teste em: https://${DOMAIN}${NC}"
echo -e "${GREEN}=====================================================${NC}"