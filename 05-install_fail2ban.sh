#!/bin/bash

# =================================================================
# Script 5: Instalação e Configuração do Fail2ban
# Objetivo: Proteger o servidor contra ataques de força bruta.
# =================================================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando a instalação do Fail2ban...${NC}"

sudo dnf install -y fail2ban mailx

sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

if [ -z "$1" ]; then
    echo "AVISO: Nenhum email fornecido. Usando o email padrão."
    DEST_EMAIL="root@localhost"
else
    DEST_EMAIL=$1
fi

sudo sed -i "s/^destemail = .*/destemail = ${DEST_EMAIL}/" /etc/fail2ban/jail.local
sudo sed -i "s/^sender = .*/sender = fail2ban@$(hostname)/" /etc/fail2ban/jail.local
sudo sed -i "s/^action = .*/action = %(action_mw)s/" /etc/fail2ban/jail.local

sudo sed -i '/^\[sshd\]/a enabled = true\nmaxretry = 3\nbantime = 3600' /etc/fail2ban/jail.local
sudo sed -i '/^\[apache-auth\]/a enabled = true\nmaxretry = 3\nbantime = 3600' /etc/fail2ban/jail.local

sudo systemctl enable --now fail2ban

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Fail2ban instalado e configurado para proteger SSH e Apache.${NC}"
echo -e "${GREEN}=====================================================${NC}"