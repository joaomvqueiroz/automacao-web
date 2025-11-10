#!/bin/bash
# Script 12: Instalação e Configuração do Certificado SSL Let's Encrypt
# Objetivo: Automatizar a obtenção e configuração de um certificado SSL com Certbot.

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

# --- 2. INSTALAÇÃO DO CERTBOT ---
echo -e "\n${YELLOW}--> Verificando/Instalando Certbot e o plugin Apache...${NC}"
# Instala o Certbot (Assumindo que o EPEL ja esta ativo, conforme os scripts anteriores)
sudo dnf install -y certbot python3-certbot-apache
if [ $? -ne 0 ]; then
    echo -e "${RED}ERRO: Falha ao instalar o Certbot. Verifique os repositorios.${NC}"
    exit 1
fi

# --- 3. PREPARAÇÃO DO APACHE ---
echo -e "\n${YELLOW}--> Preparando o Apache para a configuração SSL...${NC}"
SSL_CONF_FILE="/etc/httpd/conf.d/ssl.conf"
if [ -f "$SSL_CONF_FILE" ]; then
    echo -e "${GREEN}--> Desativando a configuração SSL padrão para evitar conflitos...${NC}"
    sudo mv "$SSL_CONF_FILE" "${SSL_CONF_FILE}.disabled"
fi

# --- 5. OBTENÇÃO E INSTALAÇÃO DO CERTIFICADO ---
echo -e "\n${YELLOW}--> PASSO 1: Obtendo o certificado para ${DOMAIN} (apenas os ficheiros)...${NC}"
sudo certbot certonly --apache --non-interactive --agree-tos \
    -m "${EMAIL}" \
    -d "${DOMAIN}" \
    -d "www.${DOMAIN}"

if [ $? -ne 0 ]; then
    echo -e "${RED}ERRO: Falha ao obter os ficheiros do certificado SSL.${NC}"
    echo -e "Verifique se a Porta 80 está aberta e redirecionada para este servidor e se o Apache está a correr."
    exit 1
fi

echo -e "\n${YELLOW}--> PASSO 2: Criando a configuração final do Apache em ${SSL_CONF_FILE}...${NC}"

# Apaga o ficheiro de configuração SSL padrão (que já foi renomeado) e cria um novo com o seu conteúdo.
sudo rm -f "$SSL_CONF_FILE"
sudo bash -c "cat > $SSL_CONF_FILE" <<EOL
<VirtualHost *:80>
    ServerName ${DOMAIN}
    ServerAlias www.${DOMAIN}
    DocumentRoot /var/www/html
    Redirect permanent / https://${DOMAIN}/
</VirtualHost>

<VirtualHost *:443>
    ServerName ${DOMAIN}
    ServerAlias www.${DOMAIN}
    DocumentRoot "/var/www/html"

    ErrorLog /var/log/httpd/${DOMAIN}_ssl_error.log
    CustomLog /var/log/httpd/${DOMAIN}_ssl_access.log combined

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/${DOMAIN}/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/${DOMAIN}/privkey.pem

    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
</VirtualHost>
EOL

echo -e "\n${YELLOW}--> PASSO 3: Reiniciando o Apache para aplicar a configuração final...${NC}"
sudo systemctl restart httpd

# --- 6. VERIFICAÇÃO DA RENOVAÇÃO AUTOMÁTICA ---
echo -e "\n${GREEN}--> Verificando o agendamento da renovação automática...${NC}"
# O Certbot instala um timer (systemd) ou cronjob para renovar automaticamente
sudo systemctl list-timers | grep 'certbot\|snap.certbot.renew'

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Certificado SSL de produção instalado e configurado com sucesso!${NC}"
echo -e "A renovação automatica foi agendada."
echo -e "${YELLOW}Teste em: https://${DOMAIN}${NC}"
echo -e "${GREEN}=====================================================${NC}"