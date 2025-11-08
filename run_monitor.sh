#!/bin/bash

# =================================================================
# Script de Execução do Monitor Python
# Objetivo: Executar o monitor.py e enviar o relatório por email.
# =================================================================

# Diretório onde os scripts estão localizados
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ "$#" -ne 1 ]; then
    echo "ERRO: Uso incorreto."
    echo "Uso: ./run_monitor.sh <email_destinatario>"
    exit 1
fi

RECIPIENT_EMAIL=$1
SUBJECT="Relatório Diário de Monitorização do Servidor LAMP"

# Executa o script Python e captura o seu output
REPORT_BODY=$(python3 "${SCRIPT_DIR}/monitor.py")

# Envia o relatório por email usando mailx
echo "$REPORT_BODY" | mailx -s "$SUBJECT" "$RECIPIENT_EMAIL"