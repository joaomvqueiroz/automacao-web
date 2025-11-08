#!/bin/bash
# Script 11: Configuração de Alertas de Segurança e Sincronização NTP
# Objetivo: Ativar alertas de email para Fail2ban e sincronização horária.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
DEST_EMAIL="seu-email@exemplo.com" # <<< SUBSTITUIR NO FICHEIRO FINAL

echo -e "${YELLOW}--- Script 11: Configurando Monitorização e Alertas de Segurança ---${NC}"

# --- 1. CONFIGURAR O ALERTA DE EMAIL NO FAIL2BAN ---
# É necessário que o servidor SMTP esteja configurado (pacote 'postfix' ou similar)
echo -e "\n${GREEN}--> Configurando o envio de alertas do Fail2ban...${NC}"

# Ajustar o email de destino no ficheiro jail.local
JAIL_LOCAL="/etc/fail2ban/jail.local"
sudo sed -i "s/^destemail = .*/destemail = ${DEST_EMAIL}/" $JAIL_LOCAL

# Garantir que a ação de banimento inclui o envio de e-mail (mw = mail-whois)
sudo sed -i "s/^action = .*/action = %(action_mw)s/" $JAIL_LOCAL

sudo systemctl restart fail2ban
log_sucesso "Alertas de Fail2ban configurados para ${DEST_EMAIL}."

# --- 2. CONFIGURAR AUDITORIA SIMPLES (SELinux e Auditd) ---
echo -e "\n${GREEN}--> Configurando Auditoria (Geração de logs)...${NC}"

# Instalar ferramentas de auditoria e relatórios
sudo dnf install -y setools-console # Ferramenta para relatórios SELinux

# Exemplo de geração de relatório de segurança (apenas documentação)
echo -e "\n--- Relatório SELinux ---" | sudo tee /var/log/seguranca_report.log
sudo sealert -a /var/log/audit/audit.log | sudo tee -a /var/log/seguranca_report.log
log_sucesso "Relatório SELinux gerado em /var/log/seguranca_report.log."


# --- 3. CONFIGURAR SINCRONIZAÇÃO HORÁRIA (NTP) ---
# Embora já tenhamos feito isto, é bom incluí-lo para completar a fase de Manutenção
echo -e "\n${GREEN}--> Verificando e Ativando Sincronização NTP (chronyd)...${NC}"
sudo dnf install -y chrony
sudo systemctl enable --now chronyd
log_sucesso "Serviço Chrony (NTP) ativado."

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Fase de Monitorização e Continuidade concluída!${NC}"
echo -e "O seu servidor está agora protegido com alertas e sincronização horária.${NC}"
echo -e "${GREEN}=====================================================${NC}"