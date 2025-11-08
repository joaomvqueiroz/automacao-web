#!/bin/bash
# Script 5: Instalacao e Configuracao do ModSecurity (WAF)
# Objetivo: Instalar ModSecurity e regras OWASP CRS.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
MODSEC_CRS_DIR="/etc/httpd/modsecurity-crs"

echo -e "${YELLOW}--- Script 5: Instalando ModSecurity e Regras OWASP CRS ---${NC}"

# 1. INSTALACAO DOS MODULOS
sudo dnf install -y mod_security mod_security_crs git || { log_erro "Falha na instalacao do ModSecurity."; exit 1; }

# 2. CONFIGURACAO DO OWASP CRS (se nao vierem pre-instaladas)
if [ ! -d "/usr/share/modsecurity-crs" ]; then
    echo -e "${YELLOW}Aviso: Regras CRS nao encontradas no diretorio padrao. Clonando via Git...${NC}"
    sudo git clone https://github.com/coreruleset/coreruleset.git $MODSEC_CRS_DIR
    sudo mv $MODSEC_CRS_DIR/crs-setup.conf.example $MODSEC_CRS_DIR/crs-setup.conf
    # Renomear as regras de exclusao tambem e um passo importante
    # (Embora as regras estejam em /usr/share/modsecurity-crs/ em muitos sistemas)
    CRS_BASE_DIR=$MODSEC_CRS_DIR 
else
    # Se ja existe, usamos o diretorio padrao
    CRS_BASE_DIR="/usr/share/modsecurity-crs"
fi

# 3. ATIVAR O WAF E CARREGAR AS REGRAS NO APACHE
MODSEC_CONFIG_FILE="/etc/httpd/conf.d/mod_security.conf"
sudo cp $MODSEC_CONFIG_FILE ${MODSEC_CONFIG_FILE}.bak

# Adicionar as diretivas de inclusao das regras OWASP CRS
sudo bash -c "cat >> $MODSEC_CONFIG_FILE" <<EOL

# --- Configuracao OWASP CRS ---
<IfModule security2_module>
    # Modo de Deteccao: On (Bloqueio) para producao, DetectionOnly para testes
    SecRuleEngine On
    
    # Carregar as regras (Assume-se que estao em /usr/share/modsecurity-crs em instalacoes dnf)
    IncludeOptional ${CRS_BASE_DIR}/crs-setup.conf
    IncludeOptional ${CRS_BASE_DIR}/rules/*.conf
</IfModule>
EOL

# 4. REINICIAR APACHE
sudo systemctl restart httpd

log_sucesso "ModSecurity (WAF) com regras OWASP CRS instalado e ativo (Modo ON)."