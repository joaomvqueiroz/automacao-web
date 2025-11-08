#!/bin/bash

# =================================================================
# Script 2: Configuração Segura do MariaDB
# Objetivo: Automatizar o "mysql_secure_installation".
# =================================================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando a configuração de segurança do MariaDB...${NC}"
echo -e "Este script irá guiá-lo através do processo de 'mysql_secure_installation'.\n"

sudo mysql_secure_installation

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Configuração de segurança do MariaDB concluída!${NC}"
echo -e "O seu servidor de base de dados está agora mais seguro."
echo -e "${GREEN}=====================================================${NC}"