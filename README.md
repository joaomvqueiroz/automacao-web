# automacao-web

## Projeto de Automação de Servidor Web LAMP

Este repositório contém um conjunto de scripts Bash para automatizar a instalação, configuração, segurança e manutenção de um servidor web baseado na stack LAMP (Linux, Apache, MariaDB, PHP) em CentOS Stream 9.

O projeto foi desenhado para ser executado de forma sequencial e orquestrada, reduzindo a intervenção manual e garantindo um ambiente de produção reprodutível e seguro.

### Estrutura dos Scripts

A automação é dividida em scripts principais, cada um com uma responsabilidade clara:

1.  **`01-install_services.sh`**: Instala a stack LAMP (Apache, MariaDB, PHP) e os repositórios (EPEL, Remi).
2.  **`02-secure_mariadb.sh`**: Automatiza a configuração de segurança do MariaDB, definindo uma password root e removendo padrões inseguros.
3.  **`03-configure_network.sh`**: Configura um endereço IP estático na interface de rede e ajusta o `firewalld` para permitir apenas tráfego SSH, HTTP e HTTPS.
4.  **`04-setup_security.sh`**: Instala e configura ferramentas de segurança essenciais:
    *   `Fail2ban`: Para proteger SSH e Apache contra ataques de força bruta.
    *   `ModSecurity`: Atua como um Web Application Firewall (WAF) com as regras OWASP CRS.
5.  **`05-tune_performance.sh`**: Aplica otimizações de desempenho (tuning) nos ficheiros de configuração do Apache, MariaDB e PHP.
6.  **`06-setup_maintenance.sh`**: Configura rotinas de manutenção, incluindo:
    *   Backups diários automatizados (ficheiros e base de dados).
    *   Sincronização horária com NTP (`chrony`).
    *   Atualizações automáticas de segurança (`dnf-automatic`).
    *   Geração de relatórios de segurança.
7.  **`12-setup_ssl_certificate.sh`**: Automatiza a obtenção e instalação de um certificado SSL/TLS gratuito da Let's Encrypt usando o `Certbot`.

#### Scripts Auxiliares

*   **`main.sh`**: Script mestre que orquestra a execução de todos os scripts principais na ordem correta.
*   **`make_all_executable.sh`**: Utilitário para tornar todos os scripts `.sh` executáveis.
*   **`setup_db_app.sh`**: Script interativo para criar a base de dados da aplicação e um utilizador com privilégios mínimos.
*   **`setup_db_auth.sh`**: Script interativo para criar o ficheiro `/root/.my.cnf`, permitindo que os backups da base de dados sejam executados sem password.
*   **`update_duckdns.sh`**: Script interativo para configurar a atualização automática de um domínio DuckDNS.
*   **`update_php_creds.sh`**: Script interativo para injetar as credenciais da base de dados nos ficheiros PHP da aplicação.

### Como Usar

Para executar a automação completa do servidor:

1.  **Clone o repositório** para o servidor CentOS de destino:
    ```bash
    git clone <URL_DO_SEU_REPOSITORIO>
    cd <NOME_DO_DIRETORIO>
    ```

2.  **Execute o script mestre** com privilégios de `sudo`. Ele irá pedir as informações necessárias (email e domínio) e depois executará todos os outros scripts na sequência correta.
    ```bash
    sudo ./main.sh
    ```

3.  **Execute os scripts auxiliares interativos** conforme indicado no final da execução do `main.sh` para finalizar a configuração da aplicação e dos backups.
    ```bash
    sudo ./setup_db_app.sh
    sudo ./setup_db_auth.sh
    ```
