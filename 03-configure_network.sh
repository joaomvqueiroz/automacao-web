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

echo -e "\n${GREEN}--> Adicionando regras permanentes para SSH, HTTP e HTTPS...${NC}"
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

echo -e "${GREEN}--> Recarregando as regras do firewall para aplicar as alterações...${NC}"
sudo firewall-cmd --reload

echo -e "\n${GREEN}--> Verificando as regras ativas:${NC}"
sudo firewall-cmd --list-all

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Firewall configurado com sucesso!${NC}"
echo -e "${GREEN}=====================================================${NC}"