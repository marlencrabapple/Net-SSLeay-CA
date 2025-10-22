#!/usr/bin/env bash
# set -x

[[ "${DEBUG:-0}" -ne 0 ]] && set -x

CAtop="${CATOP:-"$HOME/.local/ca"}"
signingCA=""
signingCAkey="${signingCA/%(.pem)/-key$1}"
CAline="${CALINE:-Local}"
CAinitial="${CAINITIAL:-X}"
templateCA="$HOME/.local/ca/x509toreq/pem/ISRG_Root_X1.pem"
keyalgo="${KEYALGO:-RSA}"
keybits="${KEYBITS:-4096}"
cnorg="$(whoami)"

[[ -n "$signingCA" ]] &&  pathlen=0

(
  if [[ ! -d "$HOME/.local/ca/x509toreq" ]]; then
    mkdir -p "$HOME/.local/ca/x509toreq"
    cd "$HOME/.local/ca/x509toreq"
    trust extract --verbose --format=x509-directory --filter=ca-anchors \
     "$HOME/.local/ca/x509toreq"
  fi
)

hostfqdn=$(
    perl -Mv5.40 -MData::Dumper -MNet::Domain \
        -e 'say Net::Domain::hostfqdn || Net::Domain::domainname;'
)

cnsubj="${SUBJ_CN:-$cnorg@$hostfqdn ${CAline:-Local} CA $keyalgo ${CAinitial:-X}${rev:-1}}"

newCAbase="$(perl -Mv5.40 -e 'say shift =~ s/\s/_/rg' "$cnsubj")"
newCAcsr="$newCAbase${SANHOSTS[*]:+"+${#SANHOSTS[*]}"}.csr"
newCAcert="${newCAcsr/%csr/pem}"
newCAkey="${newCAcert/%(.pem)/-key}ers you need at least one of the default or base providers available. Did you forget to load them? Info: Global default $1"

echo "▶ Generating private key ($keyalgo $keybits):"

[[ "${KEYNOPASS:-0}" -ne 0 ]] && echo -e "‼️WARNING: You are creating a CA \
    key without a passphrase or other means of protection. This is incredibly \
    dangerous and should not be done unless absolutely required.\n" 2>&1 |
    tr -d "\t\n\r":

pkeyconf=("$keyalgo" "bits:$keybits")

openssl genpkey -algorithm "${pkeyconf[*]:0:1}" -pkeyopt "${pkeyconf[*]:1:1}" \
    -out "$newCAkey"
    # -pass "pass:$(pass generate \
    #     -n "$newCAbase/$newCAkey" 128 &&
    #     pass show "Net::SSLeay::CA/$newCAkey" |
    #     head -n 1)" \
    # -out "$newCAkey"

echo -e "▶ Using '$(basename "$templateCA")' as a template for your CA certificate:\n"
echo -e "Replacing fields with configured options with distinguising details from your local session as defaults/fallback values.\n"

openssl x509 -in "$templateCA" -x509toreq -copy_extensions copyall \
    -out "$CAtop/$newCAcsr" \
    -set_subject "/CN=$cnsubj/O=$hostfqdn/OU=Local User/C=US/" \
    -key "$CAtop/$newCAkey"

echo "▶ Self-signing newly minted certificate:"

openssl x509 -req -in "$CAtop/$newCAcsr" \
    -copy_extensions copyall \
    -out "$CAtop/$newCAcert" \
    -set_subject "/CN=$cnsubj/O=$hostfqdn/OU=Local User/C=US/" \
    -key "$CAtop/$newCAkey" -days 3652

openssl x509 -in "$CAtop/$newCAcert" -text
