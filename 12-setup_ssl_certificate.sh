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

# --- 4. GERAR CERTIFICADO TEMPORÁRIO E CONFIGURAR APACHE ---
echo -e "\n${YELLOW}--> PASSO 1: Gerando certificado temporário para o Apache poder iniciar...${NC}"

# Cria diretórios para os certificados temporários
sudo mkdir -p /etc/letsencrypt/live/${DOMAIN}/

# Gera o certificado autoassinado
sudo openssl req -x509 -nodes -days 1 -newkey rsa:2048 \
  -keyout /etc/letsencrypt/live/${DOMAIN}/privkey.pem \
  -out /etc/letsencrypt/live/${DOMAIN}/fullchain.pem \
  -subj "/C=PT/ST=Lisboa/L=Lisboa/O=Temporary/CN=${DOMAIN}"

echo -e "\n${YELLOW}--> PASSO 2: Criando a configuração final do Apache (com certificado temporário)...${NC}"
sudo rm -f "$SSL_CONF_FILE"
sudo bash -c "cat > $SSL_CONF_FILE" <<EOL
<VirtualHost *:80>
    ServerName ${DOMAIN}
    ServerAlias www.${DOMAIN}
    DocumentRoot /var/www/html
    # O Certbot irá gerir o redirecionamento mais tarde
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

echo -e "\n${YELLOW}--> PASSO 3: Reiniciando o Apache para carregar a configuração temporária...${NC}"
sudo systemctl restart httpd

echo -e "\n${YELLOW}--> PASSO 4: Solicitando o certificado real da Let's Encrypt...${NC}"
sudo certbot --apache --non-interactive --agree-tos --redirect --expand \
    -m "${EMAIL}" \
    -d "${DOMAIN}" \
    -d "www.${DOMAIN}"

if [ $? -ne 0 ]; then
    echo -e "${RED}ERRO: Falha ao obter o certificado real da Let's Encrypt.${NC}"
    echo -e "Verifique se o seu domínio ${DOMAIN} está a apontar para o IP público correto deste servidor."
    exit 1
fi

echo -e "\n${YELLOW}--> PASSO 5: Reiniciando o Apache para aplicar o certificado final...${NC}"
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