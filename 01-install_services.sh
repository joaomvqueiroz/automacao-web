#!/bin/bash

# =================================================================
# Script 1: Instalação dos Serviços Principais (LAMP)
# Objetivo: Instalar Apache, MariaDB, PHP e ferramentas essenciais.
# =================================================================

# Cores para feedback visual
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Iniciando a configuração do servidor LAMP...${NC}"

# --- 1. Atualização do Sistema e Repositórios ---
echo -e "\n${GREEN}--> Atualizando o sistema e instalando repositórios (EPEL, Remi)...${NC}"
sudo dnf update -y
sudo dnf install -y epel-release
sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm

# Ativar o módulo PHP 8.2 do repositório Remi
sudo dnf module reset php -y
sudo dnf module enable php:remi-8.2 -y

echo -e "${GREEN}--> Repositórios configurados com sucesso!${NC}"

# --- 2. Instalação do Apache (HTTPD) ---
echo -e "\n${GREEN}--> Instalando e configurando o servidor Apache (HTTPD)...${NC}"
sudo dnf install -y httpd
sudo systemctl enable httpd
sudo systemctl start httpd
echo -e "${GREEN}--> Apache instalado e ativo.${NC}"

# --- 3. Instalação do PHP e Módulos ---
echo -e "\n${GREEN}--> Instalando PHP 8.2 e módulos essenciais...${NC}"
sudo dnf install -y php php-cli php-mysqlnd php-gd php-xml php-json php-mbstring php-fpm
echo -e "${GREEN}--> PHP instalado com sucesso.${NC}"

# --- 4. Instalação do MariaDB Server ---
echo -e "\n${GREEN}--> Instalando o servidor de base de dados MariaDB...${NC}"
sudo dnf install -y mariadb-server
sudo systemctl enable mariadb
sudo systemctl start mariadb
echo -e "${GREEN}--> MariaDB instalado e ativo.${NC}"

# --- 5. Verificação e Teste ---
echo -e "\n${YELLOW}--> Criando ficheiro de teste info.php...${NC}"
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php > /dev/null

sudo systemctl restart httpd

echo -e "\n${YELLOW}--> Testando o acesso local ao servidor web...${NC}"
if curl -s --head http://localhost/info.php | grep "200 OK" > /dev/null; then
    echo -e "${GREEN}--> Teste de acesso local bem-sucedido (HTTP 200 OK).${NC}"
else
    echo -e "\033[0;31m--> ERRO: O servidor web não está a responder corretamente.${NC}"
fi


echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Instalação da stack LAMP concluída com sucesso!${NC}"
echo -e "Verifique o funcionamento acedendo a: http://<IP_DO_SERVIDOR>/info.php"
echo -e "${YELLOW}Lembre-se de remover o ficheiro info.php após a validação.${NC}"
echo -e "${GREEN}=====================================================${NC}"