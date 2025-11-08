# automacao-web

## Projeto de Automação de Servidor Web LAMP

Este repositório contém um conjunto de scripts para automatizar a instalação, configuração, segurança e manutenção de um servidor web baseado na stack LAMP (Linux, Apache, MariaDB, PHP) em CentOS.

### Estrutura dos Scripts

Os scripts foram desenhados para serem executados em sequência:

1.  **`01-install_services.sh`**: Instala os serviços principais (Apache, MariaDB, PHP) e repositórios necessários.

2.  **`02-secure_mariadb.sh`**: Executa o assistente interativo `mysql_secure_installation` para proteger a base de dados.

3.  **`03-configure_network.sh`**: Configura o `firewalld` para permitir apenas tráfego SSH, HTTP e HTTPS.

4.  **`04-setup_security.sh`**: Instala e configura ferramentas de segurança essenciais como `Fail2ban` e `ModSecurity` (WAF).

5.  **`05-tune_performance.sh`**: Aplica otimizações de desempenho (tuning) nos ficheiros de configuração do Apache, MariaDB e PHP.

6.  **`06-setup_maintenance.sh`**: Configura rotinas de manutenção, incluindo backups diários automatizados e atualizações de segurança.

### Como Usar

1.  Clone o repositório para o servidor de destino.
2.  Dê permissão de execução a todos os scripts: `chmod +x *.sh`.
3.  Execute os scripts na ordem numérica, começando por `./01-install_services.sh`.
