#!/bin/bash
# Script 10: Manutencao e Continuidade (Backups, Updates, NTP)
# Objetivo: Criar scripts de backup, agendar com cron e configurar dnf-automatic.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

BACKUP_DIR="/backup/lamp"
BACKUP_SCRIPT_PATH="${BACKUP_DIR}/backup_lamp.sh"

echo -e "${YELLOW}--- Script 10: Configurando Backups e Manutencao ---${NC}"

# 1. CRIAR DIRETORIO DE BACKUP E PERMISSOES
sudo mkdir -p $BACKUP_DIR
sudo chown -R root:root $BACKUP_DIR
sudo chmod 700 $BACKUP_DIR
log_sucesso "Diretorio de backup criado em $BACKUP_DIR."

# 2. CRIAR O SCRIPT DE BACKUP (mysqldump e tar)
echo -e "\n${GREEN}--> Criando script de backup lamp.sh...${NC}"
# Nota: O mysqldump exige que se use o ficheiro /root/.my.cnf ou a password - faremos a password ser pedida no ficheiro .my.cnf
sudo bash -c "cat > $BACKUP_SCRIPT_PATH" <<'EOL'
#!/bin/bash
# Script de Backup Diário Agendado

DB_NAME="sabor_do_mar"
BACKUP_DIR="/backup/lamp"
WEB_ROOT="/var/www/html"
RETENCAO=7
DATE=$(date +%Y-%m-%d_%H%M)

# 🚨 NOTA: Assuma que o ficheiro /root/.my.cnf foi criado para este script!

# Backup da Base de Dados (usa .my.cnf para autenticacao)
mysqldump --defaults-extra-file=/root/.my.cnf --all-databases | gzip > "${BACKUP_DIR}/db_backup_${DATE}.sql.gz"

# Backup dos Ficheiros Web
tar -czf "${BACKUP_DIR}/www_backup_${DATE}.tar.gz" $WEB_ROOT

# Limpeza de Backups Antigos
find $BACKUP_DIR -type f -mtime +$RETENCAO -name '*.gz' -delete

echo "Backup LAMP concluído em ${DATE}."
EOL

sudo chmod +x $BACKUP_SCRIPT_PATH
log_sucesso "Script de backup criado e executavel."

# 3. CONFIGURAR DNF-AUTOMATIC (Atualizacoes de Seguranca)
echo -e "\n${GREEN}--> Configurando dnf-automatic para atualizacoes de seguranca...${NC}"
sudo dnf install -y dnf-automatic

# Ajustar configuracao para aplicar updates
sudo sed -i 's/^apply_updates = .*/apply_updates = yes/' /etc/dnf/automatic.conf
sudo sed -i 's/^upgrade_type = .*/upgrade_type = security/' /etc/dnf/automatic.conf

sudo systemctl enable --now dnf-automatic.timer
log_sucesso "Atualizacoes de seguranca automaticas ativas."

# --- 4. CONFIGURAR CRON E NTP ---
echo -e "\n${GREEN}--> Agendando backup e configurando NTP...${NC}"

# Agendamento do backup diario (02:00h)
(sudo crontab -l 2>/dev/null; echo "0 2 * * * ${BACKUP_SCRIPT_PATH} >/dev/null 2>&1") | sudo crontab -

# Configuracao da Sincronizacao Horaria (chrony)
sudo dnf install -y chrony
sudo systemctl enable --now chronyd
log_sucesso "Backup agendado e Chrony (NTP) configurado."

# --- FIM DO SCRIPT ---