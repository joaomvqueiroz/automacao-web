#!/bin/bash

# =================================================================
# Script 5: Otimização de Desempenho (Tuning)
# Objetivo: Aplicar configurações de performance no Apache, MariaDB e PHP.
# =================================================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando a otimização de desempenho (Tuning) do servidor...${NC}"

# --- 1. Tuning do PHP (/etc/php.ini) ---
echo -e "\n${GREEN}--> Otimizando o PHP...${NC}"
PHP_INI_FILE="/etc/php.ini"

sudo cp $PHP_INI_FILE ${PHP_INI_FILE}.bak

sudo sed -i 's/^memory_limit = .*/memory_limit = 256M/' $PHP_INI_FILE
sudo sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 20M/' $PHP_INI_FILE
sudo sed -i 's/^post_max_size = .*/post_max_size = 25M/' $PHP_INI_FILE
sudo sed -i 's/^display_errors = .*/display_errors = Off/' $PHP_INI_FILE
sudo sed -i 's/^;date.timezone =/date.timezone = Europe\/Lisbon/' $PHP_INI_FILE

echo -e "${GREEN}--> Configurações do PHP aplicadas com sucesso.${NC}"

# --- 2. Tuning do MariaDB (/etc/my.cnf.d/mariadb-server.cnf) ---
echo -e "\n${GREEN}--> Otimizando o MariaDB...${NC}"
MARIADB_CONFIG_FILE="/etc/my.cnf.d/mariadb-server.cnf"

sudo cp $MARIADB_CONFIG_FILE ${MARIADB_CONFIG_FILE}.bak

sudo bash -c "cat >> $MARIADB_CONFIG_FILE" <<EOL

# --- Tuning de Performance ---
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
max_connections = 100
query_cache_size = 32M
EOL

echo -e "${GREEN}--> Configurações do MariaDB aplicadas com sucesso.${NC}"

# --- 3. Tuning do Apache (httpd.conf) ---
echo -e "\n${GREEN}--> Otimizando o Apache...${NC}"
HTTPD_CONFIG_FILE="/etc/httpd/conf/httpd.conf"

sudo cp $HTTPD_CONFIG_FILE ${HTTPD_CONFIG_FILE}.bak

sudo sed -i 's/^KeepAlive Off/KeepAlive On/' $HTTPD_CONFIG_FILE
sudo sed -i 's/^KeepAliveTimeout .*/KeepAliveTimeout 5/' $HTTPD_CONFIG_FILE

echo -e "${GREEN}--> Ativando compressão com mod_deflate...${NC}"
DEFLATE_CONF_FILE="/etc/httpd/conf.d/deflate.conf"
sudo bash -c "cat > $DEFLATE_CONF_FILE" <<'EOL'
<IfModule mod_deflate.c>
    # Tipos de ficheiro a comprimir
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css application/javascript
    # Evita que o mod_deflate seja aplicado a ficheiros ja comprimidos (imagens)
    SetOutputFilter DEFLATE
</IfModule>
EOL

echo -e "${GREEN}--> Configurações do Apache (KeepAlive e Deflate) aplicadas com sucesso.${NC}"

# --- 4. Reiniciar serviços para aplicar as alterações ---
echo -e "\n${YELLOW}--> Reiniciando serviços para aplicar as novas configurações...${NC}"
sudo systemctl restart mariadb
sudo systemctl restart httpd

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Otimização de desempenho concluída!${NC}"
echo -e "${GREEN}=====================================================${NC}"