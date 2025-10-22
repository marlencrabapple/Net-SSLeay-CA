#!/usr/bin/env bash
# set -x

# openssl genpkey -algorithm RSA -pkeyopt bits:4096 -pass "pass:$(
#     pass generate -n Net::SSLeay::CA/taargus@pi4u2.lan_Root_CA_RSA-1-key.pem 128
#     pass show Net::SSLeay::CA/taargus@pi4u2.lan_Root_CA_RSA-1-key.pem | head -n 1
# )" -out taargus@pi4u2.lan_Root_CA_RSA-1-key.pem

# openssl x509 -in x509toreq/ISRG_Root_CA_X1-1759722331342669.pem -x509toreq \
#     -copy_extensions copyall -out taargus@pi4u2.lan_Root_CA_RSA-1.pem \
#     -set_subject \
#     "/CN=taargus@pi4u2.lan Root CA RSA-1/O=pi4u2.lan/OU=Local User/C=US/" \
#     -key taargus@pi4u2.lan_Root_CA-RSA-1-key.pem

[[ "${DEBUG:-0}" -ne 0 ]] && set -x

templateCA=""
keyalgo="RSA"
keybits="4096"
user="$(whoami)"
hostfqdn=$(
    perl -Mv5.40 -MData::Dumper -MNet::Domain \
        -e 'say Net::Domain::hostfqdn || Net::Domain::domainname;'
)
#subjcn_fmtstr="%s@%s %s CA %s-%d"
#subj_cn="$(user)@$hostfqdn %s CA"
subjcn="${SUBJ_CN:-$user@$hostfqdn ${CAlvl:-Root} CA $keyago:$keybits-${line:-x}${rev:-1}}"

newCAbase="$(perl -Mv5.40 -e 'say shift =~ s/\s/_/rg' "$subjcn")"
newCAcsr="$newCAbase+${#SANHOSTS[*]}.csr"
newCAcert="${newCAcsr/%csr/pem}"
newCAkey="$newCAcert-key.pem"

echo "▶ Generating private key (RSA 4096):"

[[ "${NOPASS:-0}" -ne 0 ]] && echo -e "‼️WARNING: You are creating a CA \
    key without a passphrase or other means of protection. This is incredibly \
    dangerous and should not be done unless absolutely required.\n" 2>&1 |
    tr -d "\t\n\r"

pkeyconf=("$keyalgo" "bits:$keybits")

openssl genpkey -algorithm "${pkeyconf[*]:0:1}" -pkeyopt "${pkeyconf[*]:1:1}" \
    -pass "pass:$(pass generate \
        -n "$newCAbase/$newCAkey" 128 &&
        pass show Net::SSLeay::CA/taargus@pi4u2.lan_Root_CA_RSA-1-key.pem |
        head -n 1)" \
    -out "$newCAkey"

echo "▶ Using 'ISRG Root CA' as a template for your CA certificate:"
echo "Replacing fields with configured options with distinguising details from your local session as defaults/fallback values."

openssl x509 -in "$templateCA" -x509toreq -copy_extensions copyall \
    -out "$newCAcsr" \
    -set_subject "/CN=$/O=pi4u2.lan/OU=Local User/C=US/" \
    -key "$newCAkey"

echo "▶ Self-signing newly minted certificate:"

openssl x509 -req -in /home/nameless/nameless@cincotuf.lan_Root_CA_RSA-1.csr \
    -copy_extensions copyall \
    -out "$newCAcert" \
    -set_subject "/CN=nameless@cincotuf.lan Root CA RSA.1/O=cincotuf.lan/OU=Local User/C=US/" \
    -key "$newCAkey" -days 3652

openssl x509 -in "$newCAcert" -text
