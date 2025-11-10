#!/bin/bash

# =================================================================
# Script 3: Configuração de Rede e Firewall
# Objetivo: Abrir portas essenciais no firewalld.
# =================================================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando a configuração do Firewall (firewalld)...${NC}"

# --- 1. Configuração de IP Estático (NMCLI) ---
log_info() {
    echo -e "\033[0;34m--- $1 ---\033[0m"
}

log_info "1. Configuração da Placa de Rede (IP Estático)"

echo -e "\033[0;34mInterfaces de rede e Conexões disponíveis:\033[0m"
nmcli device status | grep -E "ethernet|wifi"
nmcli connection show | grep -E "ethernet|wifi"
echo

read -p "Digite o nome da interface de rede para o servidor (ex: ens33): " NET_IFACE
CONN_NAME=$(nmcli connection show --active | grep "$NET_IFACE" | awk '{print $1}' || echo "$NET_IFACE")

if [ -z "$CONN_NAME" ]; then
    CONN_NAME="$NET_IFACE"
fi
    
read -p "Digite o IP do servidor no formato CIDR (ex: 192.168.1.100/24): " IP_CIDR
read -p "Digite o gateway padrão: " GATEWAY
read -p "Digite o servidor DNS principal: " DNS_SERVER

log_info "Aplicando configurações de rede na conexão ${CONN_NAME}..."

nmcli connection modify "$CONN_NAME" ipv4.method manual
nmcli connection modify "$CONN_NAME" ipv4.addresses "$IP_CIDR"
nmcli connection modify "$CONN_NAME" ipv4.gateway "$GATEWAY"
nmcli connection modify "$CONN_NAME" ipv4.dns "$DNS_SERVER"

log_info "A reativar a conexão ${CONN_NAME}..."
nmcli connection up "$CONN_NAME" > /dev/null 2>&1
sleep 2

# --- 2. Configuração do Firewall ---

echo -e "\n${GREEN}--> Verificando o IP público do servidor...${NC}"
PUBLIC_IP=$(curl -s ifconfig.me)
if [ -n "$PUBLIC_IP" ]; then
    echo -e "O seu IP público é: ${YELLOW}${PUBLIC_IP}${NC}"
else
    echo -e "\033[0;31m--> ERRO: Não foi possível obter o IP público. Verifique a conexão à internet.${NC}"
fi

echo -e "\n${GREEN}--> Adicionando regras permanentes para SSH, HTTP e HTTPS...${NC}"
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

echo -e "${GREEN}--> Recarregando as regras do firewall para aplicar as alterações...${NC}"
sudo firewall-cmd --reload

echo -e "\n${GREEN}--> Verificando as regras ativas:${NC}"
sudo firewall-cmd --list-all

echo -e "\n${YELLOW}--> Testando a conectividade externa com ping...${NC}"
if ping -c 3 google.com &> /dev/null; then
    echo -e "${GREEN}--> Teste de conectividade com ping bem-sucedido.${NC}"
else
    echo -e "\033[0;31m--> ERRO: Não foi possível alcançar um host externo. Verifique as regras de firewall e a conexão de rede.${NC}"
fi

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Firewall configurado com sucesso!${NC}"
echo -e "${GREEN}=====================================================${NC}"