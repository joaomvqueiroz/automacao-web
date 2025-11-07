#!/bin/bash

# =================================================================
# Script 6: Configuração de Manutenção e Continuidade
# Objetivo: Automatizar backups diários e atualizações de segurança.
# =================================================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando a configuração das rotinas de manutenção...${NC}"

# --- 1. Configuração de Backups Diários ---
echo -e "\n${GREEN}--> Configurando backups diários...${NC}"
BACKUP_DIR="/backup/lamp"
BACKUP_SCRIPT_PATH="${BACKUP_DIR}/backup_lamp.sh"

sudo mkdir -p $BACKUP_DIR
sudo chown root:root $BACKUP_DIR
sudo chmod 700 $BACKUP_DIR

sudo bash -c "cat > $BACKUP_SCRIPT_PATH" <<'EOL'
#!/bin/bash

BACKUP_DIR="/backup/lamp"
DATE=$(date +%Y-%m-%d)

# Backup da Base de Dados (requer /root/.my.cnf configurado)
mysqldump --all-databases | gzip > "${BACKUP_DIR}/db_backup_${DATE}.sql.gz"

# Backup dos Ficheiros Web
tar -czf "${BACKUP_DIR}/www_backup_${DATE}.tar.gz" /var/www/html

# Limpeza de Backups Antigos (mantém 7 dias)
find $BACKUP_DIR -type f -mtime +7 -name '*.gz' -delete

echo "Backup LAMP concluído em ${DATE}."
EOL

sudo chmod +x $BACKUP_SCRIPT_PATH

(sudo crontab -l 2>/dev/null; echo "0 2 * * * ${BACKUP_SCRIPT_PATH}") | sudo crontab -

echo -e "${GREEN}--> Script de backup criado e agendado com sucesso!${NC}"
echo -e "${YELLOW}AVISO: Crie o ficheiro /root/.my.cnf com as credenciais do MariaDB para o backup da base de dados funcionar automaticamente.${NC}"

# --- 2. Configuração de Atualizações Automáticas ---
echo -e "\n${GREEN}--> Configurando atualizações automáticas de segurança (dnf-automatic)...${NC}"
sudo dnf install -y dnf-automatic

sudo sed -i 's/^apply_updates = .*/apply_updates = yes/' /etc/dnf/automatic.conf

sudo systemctl enable --now dnf-automatic.timer

echo -e "${GREEN}--> Atualizações automáticas configuradas e ativadas.${NC}"

# --- 3. Configuração da Rotação de Logs do Apache ---
echo -e "\n${GREEN}--> Configurando a rotação de logs para o Apache...${NC}"
LOGROTATE_CONFIG="/var/log/httpd/*.log {\n    daily\n    rotate 7\n    compress\n    missingok\n    notifempty\n    sharedscripts\n    postrotate\n        /bin/systemctl reload httpd > /dev/null 2>/dev/null || true\n    endscript\n}"
echo -e "$LOGROTATE_CONFIG" | sudo tee /etc/logrotate.d/httpd-custom > /dev/null

echo -e "${GREEN}--> Rotação de logs do Apache configurada.${NC}"

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Configuração de manutenção concluída!${NC}"
echo -e "${GREEN}=====================================================${NC}"