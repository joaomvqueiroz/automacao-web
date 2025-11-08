#!/bin/bash
# Script 2b: Atualiza credenciais de acesso à DB nos ficheiros PHP
# Deve ser executado APÓS o Script 2a

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PHP_FILES=("processa_reserva.php" "reservas_admin.php")

echo -e "${YELLOW}--- ATUALIZAÇÃO DE CREDENCIAIS NOS FICHEIROS PHP ---${NC}"

# --- 1. SOLICITAR NOVAS CREDENCIAIS ---
echo -e "\n${GREEN}--> Por favor, introduza as credenciais definidas no Script 2a.${NC}"
read -p "Nome do Utilizador da Aplicação (web_user): " APP_USER
read -sp "Password do Utilizador da Aplicação: " APP_PASS
echo

if [ -z "$APP_USER" ] || [ -z "$APP_PASS" ]; then
    echo -e "\n\033[0;31m❌ ERRO: Utilizador ou password não podem estar vazios.${NC}"
    exit 1
fi

# --- 2. INJETAR CREDENCIAIS VIA SED ---
for file in "${PHP_FILES[@]}"; do
    FILE_PATH="/var/www/html/$file"
    
    if [ -f "$FILE_PATH" ]; then
        echo -e "\n${YELLOW}--> A processar ficheiro: $file${NC}"

        # 2a. Substituir Utilizador ('root' -> 'web_user')
        sudo sed -i "s/^\$username = \".*\";/\$username = \"${APP_USER}\";/" "$FILE_PATH"

        # 2b. Substituir Password ('atec123' -> 'APP_PASS')
        # Nota: O uso de '/' no sed é substituído por '|' para evitar problemas com caracteres especiais na password.
        sudo sed -i "s|^\$password = \".*\";|\$password = \"${APP_PASS}\";|" "$FILE_PATH"

        echo -e "${GREEN}✅ SUCESSO: Credenciais atualizadas em $file.${NC}"
    else
        echo -e "\033[0;31m❌ ERRO: Ficheiro não encontrado: $FILE_PATH. Não foi possível atualizar.${NC}"
    fi
done

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Injeção de credenciais PHP concluída!${NC}"
echo -e "Os seus scripts estão agora a usar o utilizador de privilégios mínimos (${APP_USER})."
echo -e "${GREEN}=====================================================${NC}"