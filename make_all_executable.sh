#!/bin/bash

# =================================================================
# Script Auxiliar: Tornar Todos os Scripts Executáveis
# Objetivo: Aplicar 'chmod +x' a todos os ficheiros .sh no diretório.
# =================================================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Tornando todos os scripts (.sh) executáveis...${NC}"

for file in *.sh; do
    # Verifica se é um ficheiro e não o próprio script a ser executado
    if [ -f "$file" ] && [ "$file" != "$(basename "$0")" ]; then
        chmod +x "$file"
        echo -e "${GREEN}  -> Permissão de execução adicionada a: $file${NC}"
    fi
done

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}Processo concluído! Todos os scripts estão prontos para serem executados.${NC}"
echo -e "${GREEN}=====================================================${NC}"