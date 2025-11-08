#!/usr/bin/env python3

"""
Script de Monitorização e Relatório de Servidor LAMP.
Analisa logs do Fail2ban e Apache para gerar um relatório diário.
"""

import sys
import re
from collections import Counter
from datetime import datetime, timedelta

# --- Configuração ---
FAIL2BAN_LOG = '/var/log/fail2ban.log'
APACHE_ACCESS_LOG = '/var/log/httpd/access_log'
APACHE_ERROR_LOG = '/var/log/httpd/error_log'
REPORT_TIME_WINDOW_HOURS = 24  # Gerar relatório para as últimas 24 horas
TOP_N_ITEMS = 10

def parse_fail2ban_log(time_window):
    """Analisa o log do fail2ban para encontrar IPs banidos nas últimas 24 horas."""
    banned_ips = []
    # Regex para encontrar ações de banimento
    ban_regex = re.compile(r"fail2ban\.actions\s+\[\d+\]: NOTICE\s+\[(.*?)\]\s+Ban\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})")
    
    try:
        with open(FAIL2BAN_LOG, 'r') as f:
            for line in f:
                # Verifica se a linha está dentro da janela de tempo
                log_time_str = line.split(',')[0]
                try:
                    log_time = datetime.strptime(log_time_str, '%Y-%m-%d %H:%M:%S')
                    if log_time >= time_window:
                        match = ban_regex.search(line)
                        if match:
                            jail, ip = match.groups()
                            banned_ips.append({'ip': ip, 'jail': jail, 'time': log_time.strftime('%H:%M:%S')})
                except ValueError:
                    continue # Ignora linhas com formato de data inválido
    except FileNotFoundError:
        return None # Retorna None se o ficheiro não existir
    return banned_ips

def parse_apache_access_log(time_window):
    """Analisa o log de acesso do Apache para estatísticas."""
    ip_counter = Counter()
    page_counter = Counter()
    
    # Regex para extrair IP e página do formato de log 'combined'
    log_regex = re.compile(r'(\d{1...3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) - - \[(.*?)\] "GET (.*?) HTTP.*')

    try:
        with open(APACHE_ACCESS_LOG, 'r') as f:
            for line in f:
                match = log_regex.match(line)
                if match:
                    ip, time_str, page = match.groups()
                    try:
                        # Formato de data do Apache: 08/Nov/2025:02:13:43 +0000
                        log_time = datetime.strptime(time_str.split(' ')[0], '%d/%b/%Y:%H:%M:%S')
                        if log_time >= time_window:
                            ip_counter[ip] += 1
                            page_counter[page] += 1
                    except ValueError:
                        continue
    except FileNotFoundError:
        return None, None
    return ip_counter.most_common(TOP_N_ITEMS), page_counter.most_common(TOP_N_ITEMS)

def generate_report():
    """Gera o corpo do relatório de monitorização."""
    now = datetime.now()
    time_window = now - timedelta(hours=REPORT_TIME_WINDOW_HOURS)
    
    report = []
    report.append(f"Relatório de Monitorização do Servidor - {now.strftime('%Y-%m-%d %H:%M:%S')}")
    report.append("=" * 60)

    # Relatório Fail2ban
    report.append("\n[+] Relatório do Fail2ban (Últimas 24 Horas)")
    banned_ips = parse_fail2ban_log(time_window)
    if banned_ips is None:
        report.append("  - Ficheiro de log do Fail2ban não encontrado.")
    elif not banned_ips:
        report.append("  - Nenhum IP banido nas últimas 24 horas. Tudo tranquilo!")
    else:
        for ban in banned_ips:
            report.append(f"  - IP: {ban['ip']:<15} | Jail: {ban['jail']:<12} | Hora: {ban['time']}")

    # Relatório Apache
    report.append("\n[+] Relatório do Apache (Últimas 24 Horas)")
    top_ips, top_pages = parse_apache_access_log(time_window)
    if top_ips is None:
        report.append("  - Ficheiro de log de acesso do Apache não encontrado.")
    else:
        report.append(f"\n  --- Top {TOP_N_ITEMS} IPs com mais acessos ---")
        if not top_ips:
            report.append("    - Nenhum acesso registado.")
        else:
            for ip, count in top_ips:
                report.append(f"    - {ip:<15} | Acessos: {count}")

        report.append(f"\n  --- Top {TOP_N_ITEMS} Páginas mais acedidas ---")
        if not top_pages:
            report.append("    - Nenhuma página acedida.")
        else:
            for page, count in top_pages:
                report.append(f"    - {page:<40} | Acessos: {count}")

    report.append("\n" + "=" * 60)
    report.append("Fim do Relatório.")
    
    return "\n".join(report)

if __name__ == "__main__":
    try:
        report_body = generate_report()
        print(report_body)
    except Exception as e:
        print(f"Ocorreu um erro ao gerar o relatório: {e}", file=sys.stderr)
        sys.exit(1)