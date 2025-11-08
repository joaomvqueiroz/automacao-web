#!/bin/bash
# Script 9: Ajustes PHP (Tuning)
# Objetivo: Aplicar configuracoes de desempenho e seguranca no /etc/php.ini.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PHP_INI_FILE="/etc/php.ini"

echo -e "${YELLOW}--- Script 9: Ajustes de Tuning do PHP (/etc/php.ini) ---${NC}"

# 1. FAZER BACKUP DO FICHEIRO ORIGINAL
sudo cp $PHP_INI_FILE ${PHP_INI_FILE}.bak

# 2. APLICAR AJUSTES DE DESEMPENHO E SEGURANÇA VIA SED
echo -e "\n${GREEN}--> Aplicando limites de memoria e upload...${NC}"

# Ajustar Limites de Memória e Upload
# O comando sed -i 's/^DIRETIVA = .*/DIRETIVA = NOVO_VALOR/' substitui a linha inteira.
sudo sed -i 's/^memory_limit = .*/memory_limit = 256M/' $PHP_INI_FILE
sudo sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 20M/' $PHP_INI_FILE
sudo sed -i 's/^post_max_size = .*/post_max_size = 25M/' $PHP_INI_FILE

# Ajuste de Segurança: Ocultar erros em produção
sudo sed -i 's/^display_errors = .*/display_errors = Off/' $PHP_INI_FILE

# Correcao CRÍTICA de Fuso Horário
# O comando remove o ';' se existir, e define o valor.
sudo sed -i 's/^;date.timezone =.*/date.timezone = Europe\/Lisbon/' $PHP_INI_FILE
sudo sed -i 's/^date.timezone =.*/date.timezone = Europe\/Lisbon/' $PHP_INI_FILE

log_sucesso "Limites de upload/memoria e fuso horario aplicados."

# 3. REINICIAR SERVICOS
echo -e "\n${YELLOW}--> Reiniciando serviços (php-fpm e Apache) para aplicar o tuning...${NC}"
sudo systemctl restart php-fpm
sudo systemctl restart httpd

log_sucesso "Tuning do PHP concluido. Configuracoes ativas."
echo -e "${GREEN}=====================================================${NC}"