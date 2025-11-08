#!/bin/bash
# Script 2a: Criação Interativa da Base de Dados e do Utilizador da Aplicação

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}--- CONFIGURAÇÃO DA BASE DE DADOS DA APLICAÇÃO ---${NC}"

# Solicitar credenciais de Administrador (root) do MariaDB para executar comandos
read -sp "Introduza a password do utilizador ROOT do MariaDB: " DB_ROOT_PASS
echo

# --- 1. SOLICITAR CREDENCIAIS DO UTILIZADOR DA APLICAÇÃO (web_user) ---
echo -e "\n${GREEN}--> Por favor, defina o utilizador e a password que o seu SITE (PHP) irá usar.${NC}"
read -p "Nome do Utilizador da Aplicação (Ex: web_user): " APP_USER
read -sp "Password do Utilizador da Aplicação: " APP_PASS
echo

# --- 2. COMANDOS SQL PARA CRIAÇÃO ---
SQL_COMMANDS="
-- 1. Cria a base de dados do projeto
CREATE DATABASE IF NOT EXISTS sabor_do_mar;

-- 2. Cria o utilizador da aplicação e define a password
CREATE USER IF NOT EXISTS '${APP_USER}'@'localhost' IDENTIFIED BY '${APP_PASS}';

-- 3. Concede privilégios mínimos necessários para a aplicação
GRANT SELECT, INSERT, UPDATE, DELETE ON sabor_do_mar.* TO '${APP_USER}'@'localhost';

-- 4. Cria a tabela de reservas (Se não existir)
USE sabor_do_mar;
CREATE TABLE IF NOT EXISTS reservas (
    id INT(11) AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    telefone VARCHAR(20),
    data DATE NOT NULL,
    hora TIME NOT NULL,
    pessoas INT(11) NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Aplica as alterações
FLUSH PRIVILEGES;
"

# --- 3. EXECUTAR COMANDOS SQL ---
echo -e "\n${YELLOW}--> Executando comandos de criação da base de dados...${NC}"
if echo "$SQL_COMMANDS" | sudo mysql -u root -p"$DB_ROOT_PASS"; then
    echo -e "${GREEN}✅ SUCESSO: Base de dados 'sabor_do_mar' e utilizador '${APP_USER}' criados.${NC}"
    echo -e "\n${YELLOW}INFORMAÇÃO CRÍTICA:${NC} Atualize os seus ficheiros PHP (processa_reserva.php e reservas_admin.php) com:"
    echo -e "Utilizador: ${GREEN}${APP_USER}${NC}"
    echo -e "Password: ${GREEN}${APP_PASS}${NC}"
else
    echo -e "\n\033[0;31m❌ ERRO: Falha ao executar comandos SQL. Verifique a password do ROOT e os logs do MariaDB.${NC}"
fi

# --- FIM DO SCRIPT ---