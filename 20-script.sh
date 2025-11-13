#!/bin/bash

# =================================================================
# Script: Apache HTTPS + SSL + DuckDNS (IPv4 & IPv6, fallback)
# =================================================================

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}--- $1 ---${NC}"; }

echo -e "${YELLOW}--- Iniciando configuração Apache + HTTPS + DuckDNS ---${NC}"

# =================================================================
# 1. Solicitar dados do usuário
# =================================================================
log_info "1. Informações do usuário"
read -p "Digite o seu subdomínio DuckDNS (ex: sabormar): " DUCK_DOMAIN
read -p "Digite o seu token DuckDNS: " DUCK_TOKEN
read -p "Digite um e-mail para Let’s Encrypt/Apache: " SERVER_EMAIL

APACHE_DOMAIN="${DUCK_DOMAIN}.duckdns.org"
DUCK_DIR="/root/duckdns"
DUCK_SCRIPT="${DUCK_DIR}/duck.sh"
DUCK_LOG="${DUCK_DIR}/duck.log"

echo -e "${GREEN}✅ Domínio configurado: ${APACHE_DOMAIN}${NC}"
echo "--------------------------------------------------------"

# =================================================================
# 2. Detectar IPs públicos
# =================================================================
log_info "2. Detectando IPs públicos"
IPV4=$(curl -4 -s ifconfig.me)
IPV6=$(curl -6 -s ifconfig.co || echo "")

echo "IPv4 detectado: $IPV4"
if [ -n "$IPV6" ]; then
    echo "IPv6 detectado: $IPV6"
else
    echo "⚠️ Nenhum IPv6 detectado"
fi
echo "--------------------------------------------------------"

# =================================================================
# 3. Configuração VirtualHosts temporários
# =================================================================
log_info "3. Criando VirtualHosts Apache temporários"

HTTP_CONF="/etc/httpd/conf.d/vhost_http_${DUCK_DOMAIN}.conf"
SSL_CONF="/etc/httpd/conf.d/vhost_ssl_${DUCK_DOMAIN}.conf"
TEMP_CERT_DIR="/etc/pki/tls"

sudo mkdir -p "${TEMP_CERT_DIR}/certs" "${TEMP_CERT_DIR}/private"

# Certificado temporário self-signed
sudo openssl req -x509 -nodes -days 1 \
  -newkey rsa:2048 \
  -keyout "${TEMP_CERT_DIR}/private/localhost.key" \
  -out "${TEMP_CERT_DIR}/certs/localhost.crt" \
  -subj "/C=PT/ST=Lisboa/L=Lisboa/O=${DUCK_DOMAIN}/OU=IT/CN=localhost"

# VirtualHost HTTP
sudo bash -c "cat > ${HTTP_CONF}" <<EOF_HTTP
<VirtualHost *:80>
    ServerName ${APACHE_DOMAIN}
    DocumentRoot /var/www/html
    Redirect permanent / https://${APACHE_DOMAIN}/
</VirtualHost>
EOF_HTTP

# VirtualHost HTTPS temporário
sudo bash -c "cat > ${SSL_CONF}" <<EOF_SSL
<VirtualHost *:443>
    ServerName ${APACHE_DOMAIN}
    ServerAdmin ${SERVER_EMAIL}
    DocumentRoot "/var/www/html"

    ErrorLog logs/${DUCK_DOMAIN}_ssl_error.log
    CustomLog logs/${DUCK_DOMAIN}_ssl_access.log combined

    <Directory "/var/www/html">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    SSLEngine on
    SSLCertificateFile ${TEMP_CERT_DIR}/certs/localhost.crt
    SSLCertificateKeyFile ${TEMP_CERT_DIR}/private/localhost.key

    SSLProtocol all -SSLv2 -SSLv3
    SSLCipherSuite HIGH:!aNULL:!MD5
    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
</VirtualHost>
EOF_SSL

echo -e "${GREEN}✔️ VirtualHosts temporários criados${NC}"
echo "--------------------------------------------------------"

# =================================================================
# 4. Instalar Apache, mod_ssl e Certbot
# =================================================================
log_info "4. Instalando pacotes Apache/SSL/Certbot"
sudo dnf install epel-release -y
sudo dnf install httpd mod_ssl openssl certbot python3-certbot-apache -y

if ! command -v certbot &>/dev/null; then
    echo "⚠️ Certbot não encontrado, instalando via Snap..."
    sudo dnf install snapd -y
    sudo systemctl enable --now snapd.socket
    sudo snap install core
    sudo snap refresh core
    sudo snap install --classic certbot
    sudo ln -s /snap/bin/certbot /usr/bin/certbot
fi
echo -e "${GREEN}✔️ Pacotes instalados${NC}"
echo "--------------------------------------------------------"

# =================================================================
# 5. Configuração do firewall
# =================================================================
log_info "5. Abrir portas 80 e 443"
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
echo -e "${GREEN}✔️ Firewall configurado${NC}"
echo "--------------------------------------------------------"

# =================================================================
# 6. Reiniciar Apache
# =================================================================
log_info "6. Reiniciar Apache"
sudo apachectl configtest
sudo systemctl restart httpd
sudo systemctl enable httpd
echo -e "${GREEN}✔️ Apache reiniciado${NC}"
echo "--------------------------------------------------------"

# =================================================================
# 7. Configuração DuckDNS
# =================================================================
log_info "7. Configuração DuckDNS"
sudo mkdir -p "$DUCK_DIR" && sudo chmod 700 "$DUCK_DIR"

sudo bash -c "cat > ${DUCK_SCRIPT}" <<EOF
#!/bin/bash
URL="https://www.duckdns.org/update?domains=${DUCK_DOMAIN}&token=${DUCK_TOKEN}&ip=${IPV4}"
EOF

if [ -n "$IPV6" ]; then
    sudo bash -c "echo 'URL=\"\${URL}&ipv6=${IPV6}\"' >> ${DUCK_SCRIPT}"
fi

sudo bash -c "cat >> ${DUCK_SCRIPT}" <<'EOF2'
echo url="${URL}" | curl -k -o /root/duckdns/duck.log -K -
DATE=$(date)
echo "$DATE - Atualização executada" >> /root/duckdns/duck.log
EOF2

sudo chmod 700 "$DUCK_SCRIPT"

# Cron automático
(sudo crontab -l 2>/dev/null; echo "*/5 * * * * ${DUCK_SCRIPT} >/dev/null 2>&1") | sudo crontab -

# Teste inicial
sudo bash "$DUCK_SCRIPT"
if grep -q "OK" "$DUCK_LOG" 2>/dev/null; then
    echo -e "${GREEN}✔️ DuckDNS atualizado com sucesso${NC}"
else
    echo -e "${YELLOW}⚠️ Verifique ${DUCK_LOG}${NC}"
fi
echo "--------------------------------------------------------"

# =================================================================
# 8. Emitir certificado Let’s Encrypt com fallback
# =================================================================
log_info "8. Emitir certificado Let’s Encrypt"

LE_DIR="/etc/letsencrypt/live/${APACHE_DOMAIN}"
ISSUED=false

# Tentativa 1: Apache plugin
if certbot --apache -d "$APACHE_DOMAIN" --non-interactive --agree-tos -m "$SERVER_EMAIL"; then
    echo -e "${GREEN}✔️ Certificado emitido com Apache plugin${NC}"
    ISSUED=true
else
    echo -e "${YELLOW}⚠️ Apache plugin falhou. Tentando Standalone...${NC}"
    sudo systemctl stop httpd
    if certbot certonly --standalone -d "$APACHE_DOMAIN" --non-interactive --agree-tos -m "$SERVER_EMAIL"; then
        echo -e "${GREEN}✔️ Certificado emitido com Standalone${NC}"
        ISSUED=true
    else
        echo -e "${RED}❌ Falha ao emitir certificado Let’s Encrypt${NC}"
    fi
    sudo systemctl start httpd
fi

echo -e "\n${YELLOW}--- ✅ Script concluído. DuckDNS + Apache + SSL/Let’s Encrypt configurado ---${NC}"

