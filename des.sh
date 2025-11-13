#!/bin/bash

# =================================================================
# Script de Desinstalação e Limpeza
# Objetivo: Reverter as configurações e remover os pacotes
#           instalados pelos scripts de automação.
# =================================================================

# --- Cores ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Funções auxiliares ---
log_info() {
    echo -e "${BLUE}--- $1 ---${NC}"
}

log_ok() {
    echo -e "${GREEN}✔ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}✖ $1${NC}"
}


echo -e "${YELLOW}=====================================================${NC}"
echo -e "${YELLOW}==    INICIANDO SCRIPT DE DESINSTALAÇÃO E LIMPEZA    ==${NC}"
echo -e "${YELLOW}=====================================================${NC}"
echo -e "${RED}AVISO: Este script irá remover serviços e configurações."
read -p "Tem a certeza que deseja continuar? (s/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 1
fi

# --- 1. Verificação de permissões ---
if [ "$EUID" -ne 0 ]; then
    log_error "Execute este script como root (sudo)."
    exit 1
fi

# --- 2. Parar e desativar serviços ---
log_info "2. A parar e desativar serviços..."
systemctl stop httpd mariadb php-fpm fail2ban chronyd 2>/dev/null
systemctl disable httpd mariadb php-fpm fail2ban chronyd 2>/dev/null
log_ok "Serviços parados e desativados."

# --- 3. Reverter configurações do Firewall ---
log_info "3. A reverter regras do Firewall (Firewalld)..."
firewall-cmd --permanent --remove-service=http >/dev/null 2>&1
firewall-cmd --permanent --remove-service=https >/dev/null 2>&1
firewall-cmd --reload
log_ok "Portas 80 (http) e 443 (https) fechadas."

# --- 4. Remover pacotes instalados ---
log_info "4. A remover pacotes de software (LAMP, Fail2ban, etc.)..."
dnf remove -y httpd mod_ssl mariadb-server php* fail2ban certbot python3-certbot-apache remi-release epel-release chrony

# Limpeza de pacotes que podem ter sido instalados via Snap
if command -v snap &> /dev/null; then
    snap remove certbot 2>/dev/null
fi

dnf autoremove -y
log_ok "Pacotes removidos."

# --- 5. Remover ficheiros de configuração e logs ---
log_info "5. A remover ficheiros de configuração, logs e dados..."

# Apache e ModSecurity
rm -rf /etc/httpd/conf.d/vhost_*
rm -rf /etc/httpd/conf.d/mod_security.conf
rm -rf /etc/httpd/modsecurity-crs
log_ok "Configurações do Apache e ModSecurity removidas."

# MariaDB (incluindo dados)
rm -rf /var/lib/mysql
rm -f /etc/my.cnf.bak_*
log_ok "Dados e backups de configuração do MariaDB removidos."

# PHP
rm -f /etc/php.ini.bak_*
rm -f /var/www/html/info.php
log_ok "Backups de configuração do PHP e info.php removidos."

# Fail2ban
rm -rf /etc/fail2ban
log_ok "Configurações do Fail2ban removidas."

# Let's Encrypt / Certificados
rm -rf /etc/letsencrypt
rm -rf /etc/pki/tls/private/localhost.key
rm -rf /etc/pki/tls/certs/localhost.crt
log_ok "Certificados (Let's Encrypt e self-signed) removidos."

# DuckDNS
rm -rf /root/duckdns
# Remove a linha do cronjob
(crontab -l 2>/dev/null | grep -v "/root/duckdns/duck.sh") | crontab -
log_ok "Configuração do DuckDNS e cronjob removidos."

# Logs e Backups
rm -f /var/log/seguranca.log
rm -rf /backups
rm -f /var/log/monitor_alerts.log
rm -f /etc/logrotate.d/lamp
log_ok "Logs de segurança, backups e configurações de logrotate removidos."


# --- 6. Conclusão ---
echo
echo -e "${GREEN}=====================================================${NC}"
echo -e "${GREEN}==        PROCESSO DE LIMPEZA CONCLUÍDO          ==${NC}"
echo -e "${GREEN}=====================================================${NC}"
echo -e "${YELLOW}O sistema foi revertido para um estado mais limpo."
echo -e "${YELLOW}Uma reinicialização ('reboot') é recomendada.${NC}"