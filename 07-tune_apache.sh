#!/bin/bash
# Script 7: Tuning do Apache (KeepAlive, Timeouts, Deflate)
# Objetivo: Otimizar o desempenho das conexoes HTTP e HTTPS.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

HTTPD_CONF_FILE="/etc/httpd/conf/httpd.conf"
MPM_CONF_FILE="/etc/httpd/conf.modules.d/00-mpm.conf"

echo -e "${YELLOW}--- Script 7: Tuning do Apache (Conexões e MPM) ---${NC}"

# --- 1. AJUSTES GLOBAIS DE CONEXAO (httpd.conf) ---
echo -e "\n${GREEN}--> Ajustando KeepAlive e Timeouts...${NC}"

# Substituir KeepAlive Off por On e ajustar Timeouts
sudo sed -i 's/^KeepAlive Off/KeepAlive On/' $HTTPD_CONF_FILE
sudo sed -i 's/^KeepAliveTimeout .*/KeepAliveTimeout 5/' $HTTPD_CONF_FILE
sudo sed -i 's/^Timeout .*/Timeout 60/' $HTTPD_CONF_FILE

# --- 2. OTIMIZACAO DO MPM (Multi-Processing Module) ---
echo -e "\n${GREEN}--> Ajustando MaxRequestWorkers (MPM Event)...${NC}"

# Adicionar/Ajustar configuracoes do MPM Event para 2GB RAM
# A diretiva MaxRequestWorkers define o MaxClients
sudo bash -c "cat >> $MPM_CONF_FILE" <<EOL
# --- AJUSTES DE TUNING ---
<IfModule mpm_event_module>
    MaxRequestWorkers 150
</IfModule>
EOL

# --- 3. ATIVACAO DA COMPRESSAO (mod_deflate) ---
echo -e "\n${GREEN}--> Ativando a compressao Gzip (mod_deflate)...${NC}"

# Adicionar bloco de configuracao para mod_deflate em ficheiro separado
DEFLATE_CONF="/etc/httpd/conf.d/deflate.conf"

sudo bash -c "cat > $DEFLATE_CONF" <<EOL
<IfModule mod_deflate.c>
    # Tipos de ficheiro a comprimir
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css application/javascript
    # Evita que o mod_deflate seja aplicado a ficheiros ja comprimidos (imagens)
    SetOutputFilter DEFLATE
</IfModule>
EOL

# --- 4. REINICIAR SERVICOS ---
sudo systemctl restart httpd

echo -e "${GREEN}=====================================================${NC}"
log_sucesso "Tuning do Apache concluido. KeepAlive e Compressao ativos."
echo -e "${GREEN}=====================================================${NC}"