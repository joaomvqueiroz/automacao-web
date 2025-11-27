#!/bin/bash

# ==============================================================================
# 1. VARIÁVEIS DE CONEXÃO E CONFIGURAÇÃO
#
#    ATENÇÃO: Este script assume que você está executando como um utilizador
#    que pode autenticar-se como 'root' no MariaDB/MySQL.
# ==============================================================================
DB_NAME="sabor_do_mar"
DB_USER="admin"
DB_PASS="atec123"
DB_ROOT_PASS="SUA_SENHA_ROOT_AQUI" # Substitua pela sua senha de root do MariaDB/MySQL

# Comando de conexão padrão ao MySQL/MariaDB como root
MYSQL_CMD="mysql -u root -p${DB_ROOT_PASS}"


# ==============================================================================
# 2. DEFINIÇÃO DOS COMANDOS SQL
# ==============================================================================
SQL_COMMANDS="
-- 1. Cria o Banco de Dados (DB)
CREATE DATABASE IF NOT EXISTS ${DB_NAME};

-- 2. Cria o Utilizador '${DB_USER}' e atribui a senha '${DB_PASS}' para acesso local
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';

-- 3. Atribui todas as permissões no DB ao utilizador
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';

-- 4. Recarrega as permissões
FLUSH PRIVILEGES;

-- 5. Seleciona o Banco de Dados
USE ${DB_NAME};

-- 6. Cria a Tabela 'reservas' (Colunas: nome, email, telefone, data, hora, pessoas)
CREATE TABLE IF NOT EXISTS reservas (
    id_reserva INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL COMMENT 'Nome Completo do Cliente',
    email VARCHAR(255) COMMENT 'Endereço de E-mail do Cliente',
    telefone VARCHAR(20) COMMENT 'Número de Telefone de Contato',
    data DATE NOT NULL COMMENT 'Data solicitada da reserva',
    hora TIME NOT NULL COMMENT 'Hora da reserva (intervalo 10:00 - 22:00)',
    pessoas SMALLINT NOT NULL COMMENT 'Número de pessoas na reserva',
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Data e hora em que o registro foi criado'
);

-- 7. Exemplo de Inserção de Dados (Opcional, para teste)
INSERT INTO reservas (nome, email, telefone, data, hora, pessoas)
VALUES ('Joana Santos', 'joana.santos@mail.pt', '919876543', '2026-02-20', '21:00:00', 3);
"

# ==============================================================================
# 3. EXECUÇÃO DOS COMANDOS
# ==============================================================================
echo "⚙️  A executar a configuração do MariaDB..."

# Executa todos os comandos SQL definidos acima
echo "$SQL_COMMANDS" | ${MYSQL_CMD}

# Verifica o código de saída do comando MySQL/MariaDB
if [ $? -eq 0 ]; then
    echo "✅ Sucesso! O banco de dados '${DB_NAME}', o utilizador '${DB_USER}' e a tabela 'reservas' foram criados."
else
    echo "❌ Erro ao executar o script. Verifique se a senha ROOT está correta e se o MariaDB está em execução."
fi
