#!/bin/bash

# =================================================================
# Script 4: Instalação e Configuração de Segurança
# Objetivo: Instalar e configurar Fail2ban e ModSecurity.
# =================================================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando a instalação das ferramentas de segurança...${NC}"

# --- 1. Instalação e Configuração do Fail2ban ---
echo -e "\n${GREEN}--> Instalando e configurando o Fail2ban...${NC}"
sudo dnf install -y fail2ban

sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

sudo sed -i '/^\[sshd\]/a enabled = true\nmaxretry = 3\nbantime = 3600' /etc/fail2ban/jail.local

sudo systemctl enable fail2ban
sudo systemctl start fail2ban
echo -e "${GREEN}--> Fail2ban instalado e configurado para proteger o SSH.${NC}"

# --- 2. Instalação do ModSecurity e Regras OWASP CRS ---
echo -e "\n${GREEN}--> Instalando ModSecurity e as regras OWASP Core Rule Set...${NC}"
sudo dnf install -y mod_security mod_security_crs git

if [ ! -d "/etc/httpd/modsecurity-crs" ]; then
    sudo git clone https://github.com/coreruleset/coreruleset.git /etc/httpd/modsecurity-crs
    sudo mv /etc/httpd/modsecurity-crs/crs-setup.conf.example /etc/httpd/modsecurity-crs/crs-setup.conf
    sudo mv /etc/httpd/modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /etc/httpd/modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
fi

MODSEC_CONFIG_APACHE="
<IfModule security2_module>
    SecRuleEngine On
    Include /etc/httpd/modsecurity-crs/crs-setup.conf
    Include /etc/httpd/modsecurity-crs/rules/*.conf
</IfModule>
"
echo "$MODSEC_CONFIG_APACHE" | sudo tee /etc/httpd/conf.d/mod_security.conf > /dev/null

sudo systemctl restart httpd
echo -e "${GREEN}--> ModSecurity com regras OWASP CRS instalado e ativo.${NC}"

# --- 3. Verificação do SELinux ---
echo -e "\n${GREEN}--> Verificando o estado do SELinux...${NC}"
sestatus | grep "Current mode"
echo -e "O SELinux deve estar em modo 'enforcing' para máxima segurança."

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Ferramentas de segurança instaladas e configuradas!${NC}"
echo -e "Fail2ban está a monitorizar o SSH."
echo -e "ModSecurity (WAF) está a proteger o Apache."
echo -e "${GREEN}=====================================================${NC}"