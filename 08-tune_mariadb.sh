#!/bin/bash
# Script 8: Tuning do MariaDB (Buffers e Cache)
# Objetivo: Otimizar o uso de RAM e desempenho das queries (Cap. 5.2).

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

MARIADB_CONF_FILE="/etc/my.cnf.d/mariadb-server.cnf"

echo -e "${YELLOW}--- Script 8: Tuning do MariaDB (Buffers e Cache) ---${NC}"

# 1. FAZER BACKUP DO FICHEIRO DE CONFIGURACAO ORIGINAL
sudo cp $MARIADB_CONF_FILE ${MARIADB_CONF_FILE}.bak

# 2. ADICIONAR DIRETIVAS DE TUNING NA SECCAO [mysqld]
# O comando sed -i '/^\[mysqld\]/a' adiciona as diretivas após [mysqld]

sudo sed -i '/^\[mysqld\]/a innodb_buffer_pool_size = 1G' $MARIADB_CONF_FILE
sudo sed -i '/^\[mysqld\]/a innodb_log_file_size = 256M' $MARIADB_CONF_FILE
sudo sed -i '/^\[mysqld\]/a max_connections = 100' $MARIADB_CONF_FILE
sudo sed -i '/^\[mysqld\]/a query_cache_size = 32M' $MARIADB_CONF_FILE

log_sucesso "Diretivas de tuning do MariaDB injetadas."

# 3. REINICIAR O MARIADB
sudo systemctl restart mariadb

log_sucesso "MariaDB reiniciado. Buffers e Cache aplicados."
echo -e "${GREEN}=====================================================${NC}"
echo -e "${GREEN}Tuning do MariaDB concluido!${NC}"
echo -e "Verifique o estado com: sudo mysql -u root -p -e 'SHOW VARIABLES LIKE \"innodb_buffer_pool_size\";'"
echo -e "${GREEN}=====================================================${NC}"