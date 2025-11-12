#!/bin/bash

# =================================================================
# Script 6: Configuração do Web Application Firewall (ModSecurity e OWASP CRS)
# Objetivo: Instalar ModSecurity, carregar as regras OWASP CRS, e ativar o WAF.
# =================================================================

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MODSEC_DIR="/etc/httpd/modsecurity-crs"
HTTPD_CONF_DIR="/etc/httpd"
MODSEC_CONF="$HTTPD_CONF_DIR/conf.d/mod_security.conf"
CRS_GIT_REPO="https://github.com/coreruleset/coreruleset.git"

log_info() {
    echo -e "${BLUE}--- $1 ---${NC}"
}

echo -e "${YELLOW}--- 🛠️ Iniciando a Configuração do ModSecurity (WAF) ---${NC}"

# 1. Instalar o Módulo ModSecurity para Apache
log_info "1. Instalação do Módulo ModSecurity"
echo ">> A instalar o pacote mod_security..."
sudo dnf install mod_security -y

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ERRO: A instalação do ModSecurity falhou. A sair.${NC}"
    exit 1
fi
echo -e "${GREEN}✔️ ModSecurity instalado com sucesso.${NC}"
echo "--------------------------------------------------------"

# 2. Instalar as Regras OWASP CRS
log_info "2. Instalação e Configuração das Regras OWASP CRS"

echo ">> A criar diretório de regras: $MODSEC_DIR"
sudo mkdir -p "$MODSEC_DIR"
sudo cd "$MODSEC_DIR" || { echo -e "${RED}❌ ERRO: Falha ao mudar para o diretório $MODSEC_DIR. A sair.${NC}"; exit 1; }

echo ">> A clonar o repositório OWASP CRS..."
sudo git clone "$CRS_GIT_REPO"
sudo mv coreruleset/* .

# Remover o diretório vazio clonado
sudo rm -rf coreruleset/

# Copiar ficheiros de exclusão de exemplo (essencial para evitar erros)
echo ">> A copiar ficheiros de exclusão de regras de exemplo..."
sudo cp rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
sudo cp rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

echo -e "${GREEN}✔️ Regras OWASP CRS instaladas em $MODSEC_DIR.${NC}"
echo "--------------------------------------------------------"

# 3. Ativar e Configurar o ModSecurity no Apache
log_info "3. Ativação do WAF (Web Application Firewall)"

# A. Ativar SecRuleEngine On
echo ">> A definir 'SecRuleEngine On' e a incluir as regras no $MODSEC_CONF..."

# Sobrescrever ou garantir SecRuleEngine On no ficheiro principal
if [ -f "$MODSEC_CONF" ]; then
    # Substitui a linha para garantir que está Ativo
    sudo sed -i 's/SecRuleEngine .*/SecRuleEngine On/' "$MODSEC_CONF"
else
    # Se o ficheiro não existir, criamos (cenário raro)
    echo "SecRuleEngine On" | sudo tee "$MODSEC_CONF" > /dev/null
fi

# B. Adicionar includes para carregar as regras
# Garantir que os includes do CRS estão no ficheiro de configuração (o relatório sugere adicionar):
echo ">> A adicionar includes das regras OWASP CRS..."
echo -e "\nIncludeOptional $MODSEC_DIR/crs-setup.conf" | sudo tee -a "$MODSEC_CONF" > /dev/null
echo -e "IncludeOptional $MODSEC_DIR/rules/*.conf" | sudo tee -a "$MODSEC_CONF" > /dev/null

echo -e "${GREEN}✔️ ModSecurity configurado para o modo ativo (SecRuleEngine On).${NC}"
echo "--------------------------------------------------------"

# 4. Reiniciar o Apache e Testar
log_info "4. Validação e Reinício do Apache"
echo ">> A reiniciar o Apache para aplicar o WAF..."
sudo systemctl restart httpd

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✔️ Apache reiniciado com sucesso. ModSecurity está ativo.${NC}"
    
    # Teste Simulado (Baseado no seu relatório)
    echo -e "\n${YELLOW}>> TESTE DE PROTEÇÃO SIMULADO (Tentativa de XSS):${NC}"
    echo "   (Resultado esperado: HTTP 403 Forbidden)"
    
    # Usar o curl para simular um ataque XSS no parâmetro 'q'
    # Isto simula o teste do relatório: curl -I "http://127.0.0.1/?q=<script>alert(1)</script>"
    CURL_TEST=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1/?q=<script>alert(1)</script>")

    if [ "$CURL_TEST" == "403" ]; then
        echo -e "${GREEN}🎉 TESTE BEM-SUCEDIDO: O WAF bloqueou o ataque (Código HTTP 403 Forbidden).${NC}"
    else
        echo -e "${RED}❌ TESTE FALHOU: O código HTTP retornado foi $CURL_TEST. O WAF pode não estar a funcionar corretamente.${NC}"
    fi
else
    echo -e "${RED}❌ ERRO: Falha ao reiniciar o Apache. Verifique a sintaxe da configuração do ModSecurity (sudo apachectl configtest).${NC}"
fi

echo -e "\n${YELLOW}--- ✅ Script de Configuração do ModSecurity Concluído ---${NC}"
