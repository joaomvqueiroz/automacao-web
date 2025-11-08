#!/bin/bash
set -euo pipefail

# ==========================================================
# Script de Configuração de Rede Estática (NMCLI)
# ==========================================================

# ----------------------------------------------------------
# Funções de Log e Estilo
# ----------------------------------------------------------
LOG_SUCCESS='\033[0;32m'
LOG_ERROR='\033[0;31m'
LOG_INFO='\033[0;34m'
LOG_WARN='\033[1;33m'
LOG_NC='\033[0m'

log_success() {
    echo -e "${LOG_SUCCESS}✅ $1${LOG_NC}"
}
log_error() {
    echo -e "${LOG_ERROR}❌ ERRO: $1${LOG_NC}"
}
log_info() {
    echo -e "${LOG_INFO}--- $1 ---${LOG_NC}"
}
log_warn() {
    echo -e "${LOG_WARN}⚠️ $1${LOG_NC}"
}

# ----------------------------------------------------------
# VARIÁVEIS GLOBAIS
# ----------------------------------------------------------
NET_IFACE=""
CONN_NAME=""
SERVER_IP=""
CIDR=""
IP_CIDR=""
GATEWAY=""
DNS_SERVER=""
DNS2=""

# ----------------------------------------------------------
# 1. Configuração da Placa de Rede (com NMCLI)
# ----------------------------------------------------------
configurar_rede_estatica() {
    log_info "1. Configuração da Placa de Rede (IP Estático)"

    echo -e "${LOG_INFO}Interfaces de rede e Conexões disponíveis:${LOG_NC}"
    nmcli device status | grep -E "ethernet|wifi"
    nmcli connection show | grep -E "ethernet|wifi"
    echo

    read -p "Digite o nome da interface ou da conexão de rede para o servidor: " NET_IFACE

    # Tenta descobrir o nome da CONEXÃO (mais seguro)
    CONN_NAME=$(nmcli connection show --active | grep "$NET_IFACE" | awk '{print $1}' || echo "$NET_IFACE")
    
    # Se a conexão ainda não estiver ativa, usa o nome da interface como nome da conexão
    if [ -z "$CONN_NAME" ] || ! nmcli connection show | grep -q "$CONN_NAME"; then
        CONN_NAME="$NET_IFACE"
    fi

    if ! nmcli device status | grep -q "$NET_IFACE" && ! nmcli connection show | grep -q "$CONN_NAME"; then
        log_error "Interface ou Conexão '$NET_IFACE' não encontrada. Verifique o nome correto e tente novamente."
        exit 1
    fi

    echo
    read -p "Digite o IP do servidor no formato CIDR (ex: 192.168.1.2/24): " IP_CIDR
    SERVER_IP=$(echo "$IP_CIDR" | cut -d'/' -f1)
    CIDR=$(echo "$IP_CIDR" | cut -d'/' -f2)
    
    read -p "Digite o gateway padrão: " GATEWAY
    read -p "Digite o servidor DNS principal: " DNS_SERVER
    read -p "Digite o servidor DNS secundário (opcional): " DNS2

    log_info "Aplicando configurações de rede na conexão ${CONN_NAME}..."
    
    # 1. Limpa qualquer configuração anterior (incluindo DHCP) e desabilita o IPv6
    nmcli connection modify "$CONN_NAME" ipv4.method disabled ipv6.method ignore

    # 2. Define o IP estático e demais parâmetros
    nmcli connection modify "$CONN_NAME" ipv4.method manual
    nmcli connection modify "$CONN_NAME" ipv4.addresses "$IP_CIDR"
    nmcli connection modify "$CONN_NAME" ipv4.gateway "$GATEWAY"
    
    if [ -z "$DNS2" ]; then
        nmcli connection modify "$CONN_NAME" ipv4.dns "$DNS_SERVER"
    else
        nmcli connection modify "$CONN_NAME" ipv4.dns "$DNS_SERVER,$DNS2"
    fi

    # 3. Ativação da Conexão
    log_info "A reativar a conexão ${CONN_NAME}..."
    nmcli connection up "$CONN_NAME" > /dev/null 2>&1
    
    sleep 2
    # 4. Confirmação
    if ip addr show "$NET_IFACE" | grep -q "$SERVER_IP"; then
        log_success "Configuração da interface $NET_IFACE (Conexão ${CONN_NAME}) concluída com sucesso."
    else
        log_error "Falha ao configurar a interface de rede. Verifique os logs do NetworkManager."
        exit 1
    fi
}

# ----------------------------------------------------------
# Fluxo de Execução Principal
# ----------------------------------------------------------
main() {
    log_info "Verificando se o usuário é root..."
    if [ "$EUID" -ne 0 ]; then
        log_error "Por favor, execute este script como root: sudo ./setup_static_ip.sh"
        exit 1
    fi

    echo "================================================="
    echo "  Iniciando Setup de Rede Estática (NMCLI)"
    echo "================================================="
    echo

    # Etapa 1: Configurar a rede estática
    configurar_rede_estatica
    
    echo "--------------------------------------------------------"
    log_success "Configuração de IP estático concluída!"
    echo "Novo IP: ${IP_CIDR} na interface: ${NET_IFACE}"
    echo "--------------------------------------------------------"
}

# Iniciar o fluxo principal
main