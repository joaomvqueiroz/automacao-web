#!/bin/bash
# Script 4: Instalacao e Configuracao do Fail2ban
# Objetivo: Proteger SSH e Apache contra ataques de forca bruta (maxretry=3).

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
DEST_EMAIL="seu-email@exemplo.com" # ALTERE PARA O SEU EMAIL

echo -e "${YELLOW}--- Script 4: Instalando e Configurando Fail2ban ---${NC}"

# 1. INSTALACAO
sudo dnf install -y fail2ban mailx || { log_erro "Falha na instalacao do Fail2ban."; exit 1; }

# 2. CONFIGURACAO LOCAL (jail.local)
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# 3. AJUSTAR PARAMETROS GLOBAIS
# Define o email de destino e a ação de banimento (banir + enviar email)
sudo sed -i "s/^destemail = .*/destemail = ${DEST_EMAIL}/" /etc/fail2ban/jail.local
sudo sed -i "s/^action = .*/action = %(action_mw)s/" /etc/fail2ban/jail.local

# 4. ATIVAR JAILS ESSENCIAIS (SSH e Apache)
# sshd: Protege acesso SSH
sudo sed -i '/^\[sshd\]/a enabled = true\nmaxretry = 3\nbantime = 3600' /etc/fail2ban/jail.local
# Apache: Protege contra forca bruta em autenticacoes web
sudo sed -i '/^\[apache-auth\]/a enabled = true\nmaxretry = 3\nbantime = 3600' /etc/fail2ban/jail.local

# 5. ATIVAR SERVICO
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
log_sucesso "Fail2ban instalado, ativo e configurado para maxretry=3."