#!/bin/bash
# Script 3: Configuração de Rede, Firewall e Redirecionamento HTTP->HTTPS

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

VHOST_CONF_FILE="/etc/httpd/conf.d/00-redirect_vhost.conf"
DOMAIN="sabordomar.duckdns.org"

echo -e "${YELLOW}--- Script 3: Configuração de Rede, Firewall e VirtualHost ---${NC}"

# --- 1. CONFIGURAÇÃO DE FIREWALL (Abrir 22, 80, 443) ---
echo -e "\n${GREEN}--> Adicionando regras permanentes para SSH, HTTP e HTTPS...${NC}"
sudo firewall-cmd --zone=public --add-service=ssh --permanent
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --zone=public --add-service=https --permanent
sudo firewall-cmd --reload
echo -e "${GREEN}✅ FirewallD configurado para 22, 80 e 443.${NC}"

# --- 2. CRIAÇÃO DA REGRA DE REDIRECIONAMENTO (HTTP -> HTTPS) ---
echo -e "\n${GREEN}--> Criando VirtualHost HTTP para redirecionamento...${NC}"

# Cria o ficheiro de configuração (VirtualHost da porta 80) com a regra de Redirect
sudo bash -c "cat > $VHOST_CONF_FILE" <<EOL
# VirtualHost da Porta 80 - Redirecionamento Obrigatório para HTTPS
<VirtualHost *:80>
    ServerName ${DOMAIN}
    ServerAlias www.${DOMAIN}
    
    # A regra 'Redirect permanent' deve ser lida antes do Certbot assumir.
    Redirect permanent / https://${DOMAIN}/
    
    ErrorLog /var/log/httpd/redirect_error.log
</VirtualHost>
EOL

echo -e "${GREEN}✅ Regra de redirecionamento HTTP->HTTPS criada em ${VHOST_CONF_FILE}${NC}"

# --- 3. REINICIAR APACHE ---
echo -e "\n${YELLOW}--> Reiniciando o Apache para aplicar o redirecionamento...${NC}"
sudo systemctl restart httpd

echo -e "${GREEN}=====================================================${NC}"
echo -e "${GREEN}Configuração de Redirecionamento e Firewall concluída.${NC}"
echo -e "Próximo passo: Executar o Certbot para configurar o VHost 443 e os certificados."
echo -e "${GREEN}=====================================================${NC}"