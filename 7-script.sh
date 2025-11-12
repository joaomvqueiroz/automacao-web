#!/bin/bash
# ===================================================================
# Script 7: Tuning do Apache (Compressão, Timeouts e MPM)
# Objetivo: Aplicar ajustes de performance baseados no hardware (RAM/CPU)
# e configurar o MPM Event.
# ===================================================================

# Cores para feedback visual
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONF_FILE="/etc/httpd/conf/httpd.conf"
MODS_DIR="/etc/httpd/conf.modules.d"
MPM_CONF="/etc/httpd/conf.modules.d/00-mpm.conf"

log_info() {
    echo -e "${BLUE}--- $1 ---${NC}"
}

echo -e "${YELLOW}--- 🛠️ Iniciando o Tuning Dinâmico do Apache HTTPD ---${NC}"

# 1. Verificações e Instalação do Apache
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}⚠️ Este script deve ser executado como root!${NC}"
    exit 1
fi

if ! command -v httpd &> /dev/null; then
    echo "❌ Apache (httpd) não está instalado. Instalando..."
    sudo dnf install -y httpd
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ ERRO ao instalar o Apache. A sair.${NC}"
        exit 1
    fi
fi

# 2. Coleta informações de hardware e cálculo de MaxRequestWorkers
TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
CPU_CORES=$(nproc)

echo -e "${BLUE}🧮 Detectado: ${TOTAL_RAM_MB}MB RAM, ${CPU_CORES} CPU cores.${NC}"

# Define valores de tuning (ajustado para o ambiente de 2GB RAM / 2vCPUs)
if [[ $TOTAL_RAM_MB -lt 2000 ]]; then
    # Valor de referência do relatório para hardware limitado
    MAX_WORKERS=150 
else
    # Lógica de cálculo se houver mais RAM disponível
    MEM_PER_CHILD=50
    MAX_WORKERS=$((TOTAL_RAM_MB / MEM_PER_CHILD))
    if [[ $MAX_WORKERS -gt 512 ]]; then MAX_WORKERS=512; fi 
fi

START_SERVERS=2      
THREADS_PER_CHILD=25 
SERVER_LIMIT=$MAX_WORKERS

echo -e "${BLUE}🧩 MaxRequestWorkers (total de threads) = ${MAX_WORKERS}${NC}"


# 3. Habilita módulos e desativa MPMs conflitantes
log_info "3. Ativação de Módulos e Seleção do MPM Event"

# Habilita módulos
sudo sed -i 's/^#\(LoadModule deflate_module modules\/mod_deflate.so\)/\1/' "$MODS_DIR"/*.conf
sudo sed -i 's/^#\(LoadModule headers_module modules\/mod_headers.so\)/\1/' "$MODS_DIR"/*.conf

# Garante que o MPM Event é o único ativado (Desativa prefork/worker)
sudo sed -i 's/^LoadModule mpm_prefork_module/#&/' "$MODS_DIR"/*.conf
sudo sed -i 's/^LoadModule mpm_worker_module/#&/' "$MODS_DIR"/*.conf
sudo sed -i 's/^#LoadModule mpm_event_module/LoadModule mpm_event_module/' "$MODS_DIR"/*.conf
echo -e "${GREEN}✔️ Módulos ativados e MPM Event selecionado.${NC}"


# 4. Aplica ajustes no httpd.conf (KeepAlive, Timeouts, Deflate)
log_info "4. Configuração de KeepAlive, Timeouts e Deflate"

# Remove parâmetros antigos e blocos de deflate antigos
sudo sed -i '/^Timeout/d' "$CONF_FILE"
sudo sed -i '/^KeepAlive/d' "$CONF_FILE"
sudo sed -i '/^MaxKeepAliveRequests/d' "$CONF_FILE"
sudo sed -i '/^KeepAliveTimeout/d' "$CONF_FILE"
sudo sed -i '/^<IfModule mod_deflate.c>/,/^<\/IfModule>/d' "$CONF_FILE" 

cat <<EOF | sudo tee -a "$CONF_FILE" > /dev/null

# ===================================================================
# 🔧 Tuning de performance Apache - $(date)
# ===================================================================

# Configurações Gerais (Capítulo 6.3.2)
Timeout 60           
KeepAlive On         
KeepAliveTimeout 5   
MaxKeepAliveRequests 100

# Compressão GZIP (mod_deflate - Capítulo 6.3.1)
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/javascript
    DeflateCompressionLevel 6
    Header append Vary User-Agent env=!dont-vary
</IfModule>
EOF


# 5. Configuração do MPM Event no conf.modules.d
log_info "5. Ajuste dos Parâmetros do MPM Event"

sudo sed -i '/<IfModule mpm_event_module>/,/<\/IfModule>/ {
    /StartServers/s/.*/    StartServers '"$START_SERVERS"'/
    /MinSpareThreads/s/.*/    MinSpareThreads 25/
    /MaxSpareThreads/s/.*/    MaxSpareThreads 75/
    /ThreadLimit/s/.*/    ThreadLimit 64/
    /ThreadsPerChild/s/.*/    ThreadsPerChild '"$THREADS_PER_CHILD"'/
    /MaxRequestWorkers/s/.*/    MaxRequestWorkers '"$MAX_WORKERS"'/
}' "$MPM_CONF"
echo -e "${GREEN}✔️ Parâmetros do MPM Event ajustados.${NC}"


# 6. Reinicia o Apache
log_info "6. Reinício do Apache"
echo "🔁 A reiniciar Apache..."
sudo systemctl enable httpd
sudo apachectl configtest
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ERRO FATAL: Falha na sintaxe da configuração do Apache. Por favor, corrija antes de reiniciar.${NC}"
    exit 1
fi
sudo systemctl restart httpd

if systemctl is-active --quiet httpd; then
    echo -e "${GREEN}✅ Apache otimizado e em execução!${NC}"
else
    echo -e "${RED}❌ Erro ao iniciar o Apache. Verifique o log.${NC}"
fi

echo -e "${GREEN}🎯 Tuning concluído!${NC}"
