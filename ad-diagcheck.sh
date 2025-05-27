#!/bin/bash

# Colors for output
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

print_section() {
  echo -e "\n${GREEN}== $1 ==${RESET}"
}

check_kerberos_status() {
  print_section "Kerberos Status Summary"

  echo -e "\n${BLUE}Kerberos ticket cache(s):${RESET}"
  found_ccache=false
  for ccache in /tmp/krb5cc_*; do
    if [ -S "$ccache" ] || [ -f "$ccache" ]; then
      echo -e "\nChecking $ccache:"
      klist -c "$ccache"
      found_ccache=true
    fi
  done
  if ! $found_ccache; then
    echo -e "${YELLOW}No Kerberos tickets found in /tmp/krb5cc_*.${RESET}"
  fi

  echo -e "\n${BLUE}Kerberos config (/etc/krb5.conf):${RESET}"
  if [ -f /etc/krb5.conf ]; then
    grep -E 'default_realm|kdc|admin_server' /etc/krb5.conf || echo -e "${YELLOW}No realm/KDC entries found.${RESET}"
  else
    echo -e "${RED}/etc/krb5.conf is missing.${RESET}"
  fi

  echo -e "\n${BLUE}Kerberos keytab (/etc/krb5.keytab):${RESET}"
  if [ -f /etc/krb5.keytab ]; then
    klist -k /etc/krb5.keytab
  else
    echo -e "${YELLOW}Keytab not found. This may be okay unless required by specific services.${RESET}"
  fi
}

# Main
print_section "AD Integration Diagnostic Script"
echo "Running checks..."

check_kerberos_status

echo -e "\n${GREEN}Diagnostics complete.${RESET}"
