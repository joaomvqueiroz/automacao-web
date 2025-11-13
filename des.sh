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
echo -e "${RED}AVISO: Este script irá PARAR e REMOVER os pacotes de serviços (Apache, MariaDB, etc.)."
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
systemctl stop httpd mariadb php-fpm fail2ban chronyd postfix snapd.socket 2>/dev/null
systemctl disable httpd mariadb php-fpm fail2ban chronyd postfix snapd.socket 2>/dev/null
log_ok "Serviços parados e desativados."

# --- 3. Remover pacotes instalados ---
log_info "3. A remover pacotes de software (LAMP, Fail2ban, etc.)..."
dnf remove -y httpd mod_ssl mod_security mariadb-server php* fail2ban certbot python3-certbot-apache remi-release epel-release chrony postfix

# Limpeza de pacotes que podem ter sido instalados via Snap
if command -v snap &> /dev/null; then
    log_info "A remover pacotes Snap..."
    snap remove certbot 2>/dev/null
    # Opcional: Descomente a linha abaixo se desejar remover o próprio Snapd
    # dnf remove -y snapd
fi

dnf autoremove -y
log_ok "Pacotes removidos."

# --- 4. Conclusão ---
echo
echo -e "${GREEN}=====================================================${NC}"
echo -e "${GREEN}==    DESINSTALAÇÃO DE SERVIÇOS CONCLUÍDA       ==${NC}"
echo -e "${GREEN}=====================================================${NC}"
echo -e "${YELLOW}Os pacotes de software foram removidos."
echo -e "${YELLOW}Ficheiros de configuração, logs e dados NÃO foram apagados.${NC}"