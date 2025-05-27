#!/bin/bash

# ad_diagcheck.sh - Diagnose Active Directory integration issues on Linux
# Author: momogitater (or your handle)
# License: MIT
#
# This script checks the status of AD integration on Linux systems.
# 本スクリプトはLinuxのAD連携状況を診断します。

# Colors for output / 出力用の色設定
GREEN="\e[32m"   # Green / 緑色
YELLOW="\e[33m"  # Yellow / 黄色
RED="\e[31m"     # Red / 赤色
RESET="\e[0m"    # Reset / リセット

# Section title printer / セクションタイトル表示
print_section() {
  echo -e "\n${YELLOW}== $1 ==${RESET}"
}

# Check if command exists / コマンド存在確認
check_cmd() {
  command -v "$1" &>/dev/null || echo -e "${RED}Missing command: $1${RESET}"
}

# Kerberos ticket check / Kerberosチケット確認
check_kerberos_ticket() {
  print_section "Kerberos Ticket (klist)"
  if klist 2>&1 | grep -q 'Default principal'; then
    klist
  else
    echo -e "${YELLOW}No default Kerberos ticket via klist. Scanning available ticket caches...${RESET}"
    local found_ticket=0
    for cache in /tmp/krb5cc_*; do
      if [[ -r "$cache" ]]; then
        echo -e "${GREEN}Found ticket cache: $cache${RESET}"
        klist -c "$cache"
        found_ticket=1
      fi
    done
    if [[ $found_ticket -eq 0 ]]; then
      echo -e "${RED}No valid Kerberos ticket found.${RESET}"
    fi
  fi
}

# Keytab file check / keytabファイル確認
check_keytab() {
  print_section "Keytab Entries (/etc/krb5.keytab)"
  if [[ -f /etc/krb5.keytab ]]; then
    klist -k /etc/krb5.keytab
  else
    echo -e "${RED}/etc/krb5.keytab not found.${RESET}"
  fi
}

# Realm join status check / ADドメイン参加状況確認
check_realm() {
  print_section "Realm Join Status"
  if realm list | grep -q 'configured: kerberos-member'; then
    realm list
  else
    echo -e "${RED}Not joined to any AD domain.${RESET}"
  fi
}

# SSSD service and config check / SSSDサービス・設定確認
check_sssd() {
  print_section "SSSD Service Status"
  systemctl is-active sssd && echo -e "${GREEN}SSSD is active${RESET}" || echo -e "${RED}SSSD is not running${RESET}"
  systemctl is-enabled sssd && echo -e "Enabled" || echo -e "${RED}Not enabled${RESET}"

  print_section "SSSD Config (/etc/sssd/sssd.conf)"
  if [[ -f /etc/sssd/sssd.conf ]]; then
    grep -E '^\[|^.*(domain|ad_domain|krb5_realm).*=' /etc/sssd/sssd.conf
  else
    echo -e "${RED}/etc/sssd/sssd.conf not found.${RESET}"
  fi
}

# DNS SRV record check / DNS SRVレコード確認
check_dns_resolution() {
  print_section "DNS Resolution for Domain Controllers"
  domain=$(realm list | awk '/domain-name:/ {print $2}')
  if [[ -z "$domain" ]]; then
    echo -e "${RED}Domain name could not be determined from realm.${RESET}"
    return
  fi
  echo "Looking up _ldap._tcp.${domain}..."
  dig +short _ldap._tcp."$domain" SRV || echo -e "${RED}DNS SRV lookup failed.${RESET}"
}

# nsswitch.conf check / nsswitch.confの確認
check_nsswitch_conf() {
  print_section "nsswitch.conf Verification"
  grep 'passwd\|group' /etc/nsswitch.conf
  echo -e "${YELLOW}Note: Ensure 'sss' is included after joining the realm and running authselect.${RESET}"
  # 備考: realm参加後、authselect実行後に'sss'が含まれていることを確認
}

# PAM config check / PAM設定の確認
check_pam_config() {
  print_section "PAM Configuration Hints"
  echo -e "${YELLOW}Note: PAM files such as /etc/pam.d/system-auth and password-auth should include pam_sss.so after authselect is configured.${RESET}"
  # 備考: /etc/pam.d/system-authやpassword-authにpam_sss.soが含まれていること
}

# Hostname consistency check / ホスト名一貫性確認
check_hostname_consistency() {
  print_section "Hostname Consistency"
  echo -n "hostname -s: "; hostname -s
  echo -n "hostname -f: "; hostname -f
  echo -n "DNS lookup:   "; getent hosts "$(hostname -f)" || echo -e "${RED}Hostname not resolvable in DNS.${RESET}"
  # ホスト名・FQDN・DNS解決の整合性を確認
}

# Start diagnostic / 診断開始
#
# 各種コマンドの存在確認
# ホスト名・ドメイン参加・Kerberos・keytab・SSSD・DNS・nsswitch・PAMを順に診断

echo -e "${GREEN}Running Active Directory integration diagnostic...${RESET}"

check_cmd klist      # Kerberosチケット確認コマンド
check_cmd realm      # ドメイン参加確認コマンド
check_cmd dig        # DNS確認コマンド
check_cmd sssctl     # SSSD管理コマンド

check_hostname_consistency   # ホスト名・DNS整合性
check_realm                 # ドメイン参加状況
check_kerberos_ticket       # Kerberosチケット
check_keytab                # keytabファイル
check_sssd                  # SSSDサービス
check_dns_resolution        # DNS SRVレコード
check_nsswitch_conf         # nsswitch.conf
check_pam_config            # PAM設定

echo -e "\n${GREEN}Diagnostic completed.${RESET}"
# 診断完了
