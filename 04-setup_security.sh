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
sudo dnf install -y fail2ban mailx # Instalar mailx para envio de emails

sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Configurar o email de destino para os alertas
DEST_EMAIL="seu-email@exemplo.com" # <-- ALTERE PARA O SEU EMAIL
sudo sed -i "s/^destemail = .*/destemail = ${DEST_EMAIL}/" /etc/fail2ban/jail.local
sudo sed -i "s/^sender = .*/sender = fail2ban@$(hostname)/" /etc/fail2ban/jail.local

# Configurar a ação de banimento para incluir o envio de email
sudo sed -i "s/^action = .*/action = %(action_mw)s/" /etc/fail2ban/jail.local

# Ativar a proteção para SSH com as novas configurações
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

# --- Teste de proteção do ModSecurity ---
echo -e "\n${YELLOW}--> Testando a proteção do ModSecurity (simulação de ataque XSS)...${NC}"
ATTACK_URL="http://localhost/index.html?param=<script>alert('xss')</script>"

if curl -s -o /dev/null -w "%{http_code}" "$ATTACK_URL" | grep "403" > /dev/null; then
    echo -e "${GREEN}--> Teste bem-sucedido! O ModSecurity bloqueou o pedido malicioso (HTTP 403).${NC}"
else
    echo -e "\033[0;31m--> AVISO: O ModSecurity não bloqueou o pedido. Verifique a configuração.${NC}"
fi

# --- 3. Verificação do SELinux ---
echo -e "\n${GREEN}--> Verificando o estado do SELinux...${NC}"
sestatus | grep "Current mode"
echo -e "O SELinux deve estar em modo 'enforcing' para máxima segurança."

# --- 4. Geração de Relatórios de Segurança e Log Centralizado ---
echo -e "\n${GREEN}--> Gerando relatórios e criando log de segurança centralizado...${NC}"
sudo dnf install -y setools-console # Garante que o 'sealert' está instalado
LOG_SEGURANCA="/var/log/seguranca.log"

echo -e "Relatório de Segurança Inicial - $(date)\n" | sudo tee $LOG_SEGURANCA
echo -e "\n--- STATUS FAIL2BAN ---\n" | sudo tee -a $LOG_SEGURANCA
sudo fail2ban-client status sshd | sudo tee -a $LOG_SEGURANCA
echo -e "\n--- ALERTAS SELINUX ---\n" | sudo tee -a $LOG_SEGURANCA
sudo sealert -a /var/log/audit/audit.log | sudo tee -a $LOG_SEGURANCA
echo -e "${GREEN}--> Relatório de segurança inicial guardado em ${LOG_SEGURANCA}${NC}"

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Ferramentas de segurança instaladas e configuradas!${NC}"
echo -e "Fail2ban está a monitorizar o SSH."
echo -e "ModSecurity (WAF) está a proteger o Apache."
echo -e "${GREEN}=====================================================${NC}"