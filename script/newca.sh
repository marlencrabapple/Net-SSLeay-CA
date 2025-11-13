#!/usr/bin/env bash
[[ "${DEBUG:-0}" -ne 0 ]] && set -x

CAtop="${CATOP:-"$HOME/.local/ca"}"

for path in "$CAtop"/{private,newcert,crl,certs,db}; do
  [[ -d "$path" ]] || mkdir -p "$path"
done

[[ -f "$CAtop/db/index" ]] || touch "$CAtop/db/index"
[[ -f "$CAtop/db/serial" ]] || openssl rand -hex 16 > ca/db/serial

signingCA="$SIGNINGCA"
signingCA_key="$SIGNINGCA_KEY"

CArank="${CARANK:-Local}"
CAinitial="${CAINITIAL:-X}"
templateCA="${CATEMPLATE:-$CAtop/x509toreq/pem/ISRG_Root_X1.pem}"
keyalgo="${KEYALGO:-RSA}"
keybits="${KEYBITS:-4096}"
cnorg="$(whoami)"

[[ -n "$signingCA" ]] && pathlen=0

(
  if [[ ! -d "$CAtop/x509toreq" ]]; then
    mkdir -p "$CAtop/x509toreq"
    
    cd "$CAtop/x509toreq"

    trust extract --verbose --format=pem-directory --filter=ca-anchors \
                  --purpose=server-auth \
                  "$CAtop/x509toreq/pem"
  fi
)

hostfqdn=$(perl -Mv5.40 -MData::Dumper -MNet::Domain -e 'say Net::Domain::hostfqdn || Net::Domain::domainname')

cnsubj="${SUBJ_CN:-$cnorg@$hostfqdn ${CArank:-Local} CA $keyalgo ${CAinitial:-X}${rev:-1}}"

newCAbase="$(perl -Mv5.40 -e 'say shift =~ s/\s/_/rg' "$cnsubj")"
newCAcsr="$newCAbase${SANHOSTS[*]:+"+${#SANHOSTS[*]}"}.csr"
newCAcert="${newCAcsr/%csr/pem}"
newCAkey="${newCAcert/%.pem/-key.pem}"

echo "▶ Generating private key ($keyalgo $keybits):"

[[ "${KEYNOPASS:-0}" -ne 0 ]] && echo -e "‼️WARNING: You are creating a CA \
    key without a passphrase or other means of protection. This is incredibly \
    dangerous and should not be done unless absolutely required.\n" 2>&1 |
    tr -d "\t\n\r":

pkeyconf=("$keyalgo" "bits:$keybits")

openssl genpkey -algorithm "${pkeyconf[*]:0:1}" -pkeyopt "${pkeyconf[*]:1:1}" \
    -out "$CAtop/private/$newCAkey"
    # -pass "pass:$(pass generate \
    #     -n "$newCAbase/$newCAkey" 128 &&-
    #     pass show "Net::SSLeay::CA/$newCAkey" |
    #     head -n 1)" \
    # -out "$newCAkey"

echo -e "▶ Using '$(basename "$templateCA")' as a template for your CA certificate:\n"
echo -e "▶ Replacing fields with configured options with distinguising details from your local session as defaults/fallback values.\n"


x509args=(-in "$templateCA" -x509toreq
    -out "$CAtop/$newCAcsr" \
    -set_subject "/CN=$cnsubj/O=$hostfqdn/OU=${SUBJ_ON:-Local User}/C=${SUBJ_C:-US}/" \
    -key "$CAtop/private/$newCAkey"
)

[[ -n "$CLREXT" ]] && x509args+=(-clrext)
[[ -n "$EXTFILE" ]] && x509args+=(-extfile "$EXTFILE")
[[ -n "$EXTENSIONS" ]] && x509args+=(-extensions "$EXTENSIONS")
[[ -n "$OPENSSL_CONF" ]] && x509args+=(-config "$OPENSSL_CONFIGH")

openssl x509 "${x509args[@]}"

echo "▶ Self-signing newly minted certificate:"

CAargs=(-in "$CAtop/$newCAcsr"
    -verbose
    -config "$OPENSSL_CONFIG"
    # -copy_extensions copyall
    -out "$CAtop/$newCAcert"
    -subj "/CN=$cnsubj/O=$hostfqdn/OU=${SUBJ_ON:-Local User}/C=${SUBJ_C:-US}/"
    -notext -rand_serial -utf8
    -days "${VALIDDAYS:-7305}")

if [[ -n "$signingCA" ]] && [[ -n "$signingCA_key" ]]; then
  CAargs+=(-cert "$signingCA" -keyfile "$signingCA_key")
else
  CAargs+=(-selfsign -keyfile "$CAtop/private/$newCAkey")
fi

[[ -n "$CLREXT" ]] && CAargs+=(-clrext)
[[ -n "$EXTFILE" ]] && CAargs+=(-extfile "$EXTFILE")
[[ -n "$EXTENSIONS" ]] && CAargs+=(-extensions "$EXTENSIONS")
[[ -n "$OPENSSL_CONFIG" ]] && CAargs+=(-config "$OPENSSL_CONFIG")

openssl ca "${CAargs[@]}"

echo "☆彡・SUCCESS!・☆彡"
echo -e "\nSucessfully generated and signed certificate authority at:\n"
echo -e "▶ 《$CAtop/$newCAcert》\n"

openssl x509 -in "$CAtop/$newCAcert" -text
