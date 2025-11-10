#!/bin/bash
set -e

# =================================================================
# Script Mestre de Automação do Servidor LAMP
# Objetivo: Orquestrar a execução de todos os scripts de configuração.
# =================================================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

run_script() {
    local script_name=$1
    shift
    local script_args=("$@")

    if [ -f "$script_name" ]; then
        echo -e "\n${BLUE}=====================================================${NC}"
        echo -e "${BLUE}==> EXECUTANDO: $script_name${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        if ! sudo "./$script_name" "${script_args[@]}"; then
            echo -e "\n${RED}ERRO: O script $script_name falhou. Abortando a execução.${NC}"
            exit 1
        fi
        echo -e "${GREEN}==> SUCESSO: $script_name concluído.${NC}"
    else
        echo -e "\n${RED}ERRO: Script $script_name não encontrado. Abortando.${NC}"
        exit 1
    fi
}

echo -e "${YELLOW}=====================================================${NC}"
echo -e "${YELLOW}== INÍCIO DA AUTOMAÇÃO COMPLETA DO SERVIDOR LAMP ==${NC}"
echo -e "${YELLOW}=====================================================${NC}"

# --- Coleta de Informações Iniciais ---
echo -e "\n${BLUE}Por favor, forneça as informações necessárias para a automação:${NC}"
read -p "Qual o seu email para alertas do Fail2ban e registo do SSL? " ADMIN_EMAIL
read -p "Qual o domínio a ser configurado (ex: sabordomar.duckdns.org)? " DOMAIN_NAME

if [ -z "$ADMIN_EMAIL" ] || [ -z "$DOMAIN_NAME" ]; then
    echo -e "${RED}ERRO: Email e Domínio são obrigatórios. Abortando.${NC}"
    exit 1
fi

# --- Verificação de Permissões ---
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}ERRO: Este script mestre deve ser executado com privilégios de root (sudo).${NC}"
  exit 1
fi

# --- Execução Sequencial dos Scripts ---

# 1. Preparação: tornar todos os outros scripts (.sh) executáveis
echo -e "\n${BLUE}=====================================================${NC}"
echo -e "${BLUE}==> PREPARANDO: Tornando scripts executáveis...${NC}"
echo -e "${BLUE}=====================================================${NC}"
for file in *.sh; do
    if [ -f "$file" ] && [ "$file" != "main.sh" ]; then
        sudo chmod +x "$file"
    fi
done
echo -e "${GREEN}==> SUCESSO: Permissões de execução aplicadas.${NC}"

# 2. Instalação dos serviços base
run_script "01-install_services.sh"

# 3. Segurança da Base de Dados
run_script "02-secure_mariadb.sh"

# 4. Configuração de Rede
run_script "03-configure_network.sh"

# 5. Segurança do Servidor (WAF, IPS)
run_script "04-selinux_policies.sh"
run_script "05-install_fail2ban.sh" "$ADMIN_EMAIL"
run_script "06-install_modsecurity.sh"

# 6. Otimização de Desempenho
run_script "07-tune_apache.sh"
run_script "08-tune_mariadb.sh"
run_script "09-tune_php.sh"

# 7. Manutenção e Continuidade
run_script "10-updates_backup.sh"
run_script "11-monitoring.sh" "$ADMIN_EMAIL"

# 8. Configuração do Certificado SSL
run_script "12-setup_ssl_certificate.sh" "$DOMAIN_NAME" "$ADMIN_EMAIL"

# 9. Configuração do DuckDNS
run_script "13-setup_duckdns.sh" "$DOMAIN_NAME"
 
# 10. Validação Final do Ambiente com Python
echo -e "\n${BLUE}=====================================================${NC}"
echo -e "${BLUE}==> EXECUTANDO SCRIPT DE VALIDAÇÃO FINAL (Python) ==${NC}"
echo -e "${BLUE}=====================================================${NC}"
sudo python3 validate_setup.py

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}== AUTOMAÇÃO CONCLUÍDA COM SUCESSO! ==${NC}"
echo -e "${GREEN}=====================================================${NC}"
echo -e "${YELLOW}O seu servidor LAMP está configurado, seguro e otimizado.${NC}"
echo -e "Acesse o seu site em: ${GREEN}https://${DOMAIN_NAME}${NC}"
echo -e "\n${BLUE}Passos manuais restantes:${NC}"
echo -e " - Execute ${YELLOW}./setup_db_app.sh${NC} para criar o utilizador da aplicação."
echo -e " - Execute ${YELLOW}./setup_db_auth.sh${NC} para configurar a autenticação do backup."
echo -e " - Configure o backup remoto editando ${YELLOW}/backup/lamp/backup_lamp.sh${NC} e configurando as chaves SSH."