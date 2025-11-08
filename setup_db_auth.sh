#!/bin/bash
# Script 10a: Configura a autenticacao do MariaDB para o Backup do Cron
# Objetivo: Criar o ficheiro /root/.my.cnf para que o mysqldump funcione sem password.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

MY_CNF_FILE="/root/.my.cnf"

echo -e "${YELLOW}--- Script 10a: Autenticação Segura do MariaDB para Backup ---${NC}"

# --- 1. SOLICITAR CREDENCIAIS DO ROOT DO MARIADB ---
echo -e "\n${GREEN}--> O script de backup precisa da password do ROOT do MariaDB para funcionar automaticamente.${NC}"
read -sp "Introduza a password do utilizador ROOT do MariaDB: " DB_ROOT_PASS
echo

# --- 2. CRIAR O FICHEIRO .my.cnf COM AS CREDENCIAIS ---
echo -e "\n${YELLOW}--> Criando o ficheiro de credenciais ${MY_CNF_FILE}...${NC}"

# Usa bash -c para garantir que o ficheiro é criado como root
sudo bash -c "cat > $MY_CNF_FILE" <<EOL
[mysqldump]
user=root
password="${DB_ROOT_PASS}"
EOL

# --- 3. DEFINIR PERMISSÕES RESTRITAS (Segurança) ---
# O ficheiro deve ser legível apenas pelo root para evitar que outros utilizadores o acedam.
sudo chmod 600 $MY_CNF_FILE
log_sucesso "Ficheiro de autenticacao criado em ${MY_CNF_FILE} com permissoes 600."

# --- 4. VERIFICAÇÃO FINAL ---
echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Autenticação de Backup configurada! O Cron pode agora executar o mysqldump.${NC}"
echo -e "Teste de permissao (deve mostrar 600 e ser legivel apenas por root):"
ls -l $MY_CNF_FILE
echo -e "${GREEN}=====================================================${NC}"