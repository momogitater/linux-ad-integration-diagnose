#!/bin/bash

# ad_diagcheck.sh - Diagnose Active Directory integration issues on Linux
# Author: momogitater (or your handle)
# License: MIT

# Colors for output
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

print_section() {
  echo -e "\n${YELLOW}== $1 ==${RESET}"
}

check_cmd() {
  command -v "$1" &>/dev/null || echo -e "${RED}Missing command: $1${RESET}"
}

check_kerberos_ticket() {
  print_section "Kerberos Ticket (klist)"
  if klist 2>&1 | grep -q 'Default principal'; then
    klist
  else
    echo -e "${RED}No valid Kerberos ticket.${RESET}"
  fi
}

check_keytab() {
  print_section "Keytab Entries (/etc/krb5.keytab)"
  if [[ -f /etc/krb5.keytab ]]; then
    klist -k /etc/krb5.keytab
  else
    echo -e "${RED}/etc/krb5.keytab not found.${RESET}"
  fi
}

check_realm() {
  print_section "Realm Join Status"
  if realm list | grep -q 'configured: kerberos-member'; then
    realm list
  else
    echo -e "${RED}Not joined to any AD domain.${RESET}"
  fi
}

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

check_nsswitch_conf() {
  print_section "nsswitch.conf Verification"
  grep 'passwd\|group' /etc/nsswitch.conf
  echo -e "${YELLOW}Note: Ensure 'sss' is included after joining the realm and running authselect.${RESET}"
}

check_pam_config() {
  print_section "PAM Configuration Hints"
  echo -e "${YELLOW}Note: PAM files such as /etc/pam.d/system-auth and password-auth should include pam_sss.so after authselect is configured.${RESET}"
}

check_hostname_consistency() {
  print_section "Hostname Consistency"
  echo -n "hostname -s: "; hostname -s
  echo -n "hostname -f: "; hostname -f
  echo -n "DNS lookup:   "; getent hosts "$(hostname -f)" || echo -e "${RED}Hostname not resolvable in DNS.${RESET}"
}

# Start diagnostic
echo -e "${GREEN}Running Active Directory integration diagnostic...${RESET}"

check_cmd klist
check_cmd realm
check_cmd dig
check_cmd sssctl

check_hostname_consistency
check_realm
check_kerberos_ticket
check_keytab
check_sssd
check_dns_resolution
check_nsswitch_conf
check_pam_config

echo -e "\n${GREEN}Diagnostic completed.${RESET}"
