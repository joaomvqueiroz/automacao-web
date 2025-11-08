#!/bin/bash

# =================================================================
# Script 2: Configuração Segura do MariaDB
# Objetivo: Automatizar o "mysql_secure_installation".
# =================================================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Gerar uma password aleatória e segura para o root do MariaDB
DB_ROOT_PASSWORD=$(openssl rand -base64 12)

echo -e "${YELLOW}Iniciando a configuração de segurança do MariaDB...${NC}"

echo -e "\n${GREEN}--> Configurando a password do utilizador 'root' e aplicando regras de segurança...${NC}"

# Comandos SQL para automatizar o mysql_secure_installation
# Nota: Usar -e para executar múltiplos comandos.
sudo mysql -u root -e "
-- Definir a password para o utilizador root
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
-- Remover utilizadores anónimos
DELETE FROM mysql.user WHERE User='';
-- Desativar login remoto para o utilizador root
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- Remover a base de dados de teste
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- Recarregar privilégios para aplicar as alterações
FLUSH PRIVILEGES;
"

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Configuração de segurança do MariaDB concluída!${NC}"
echo -e "O seu servidor de base de dados está agora mais seguro."
echo -e "${YELLOW}A nova password do root é: ${DB_ROOT_PASSWORD}${NC}"
echo "Guarde esta password num local seguro!"
echo -e "${GREEN}=====================================================${NC}"