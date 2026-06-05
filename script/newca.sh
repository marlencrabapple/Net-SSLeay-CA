#!/usr/bin/env bash
[[ "${DEBUG:-0}" -ne 0 ]] && set -x

_hostfqdn=""

info() {
	>&2 echo -e "▶ $1"
}

hostfqdn() {
  [[ -z "$_hostfqdn" ]] && _hostfqdn="$(perl \
    -Mv5.40 \
    -MNet::Domain \
    -e 'say Net::Domain::hostfqdn || Net::Domain::domainname')"

  status="$?"
  [[ $status -eq 0 ]] && echo "$_hostfqdn"

  return "$status"
}

CAtop="${CATOP:-"$HOME/.local/ca"}"

for path in "$CAtop"/{private,crl,certs,db}; do
  [[ -d $path ]] || mkdir -p "$path"
done

[[ -f "$CAtop/db/index" ]] || touch "$CAtop/db/index"
[[ -f "$CAtop/db/serial" ]] || openssl rand -hex 16 >"$CAtop/db/serial"

signingCA="${SIGNINGCA:-${ISSUER_CERT:-${CA_CERT:-$CA}}}"
signingCA_key="${SIGNINGCA_KEY:-${ISSUER_KEY:-$CA_KEY}}"

CArank="${CARANK:-Local}"
CAinitial="${CAINITIAL:-X}"
templateCA="${CATEMPLATE:-$CAtop/x509toreq/pem/ISRG_Root_X1.pem}"
keyalgo="${KEYALGO:-RSA}"
keybits="${KEYBITS:-4096}"
# subj_o="$(whoami)"

(
  if [[ ! -d "$CAtop/x509toreq" ]]; then
    mkdir -p "$CAtop/x509toreq"

    cd "$CAtop/x509toreq" || return $?

    trust extract --verbose --format=pem-directory --filter=ca-anchors \
      --purpose=server-auth \
      "./pem"
  fi
)

subj_cn="${SUBJ_CN:-$cnorg@$(hostfqdn) ${CArank:-Local} CA $keyalgo ${CAinitial:-X}${rev:-1}}"
subj_o="${SUBJ_O:-$(hostfqdn)}"
subj_ou="${SUBJ_OU:-Local User}"
subj_c="${SUBJ_C:-US}"

newCAbase="$(perl -Mv5.40 -e 'say shift =~ s/\s/_/rg' "$subj_cn")"
newCAcsr="$newCAbase${SANHOSTS[*]:+"+${#SANHOSTS[*]}"}.csr"
newCAcert="${newCAcsr/%csr/pem}"
newCAkey="${newCAcert/%.pem/-key.pem}"

info "Generating private key ($keyalgo $keybits):"

[[ ${KEYNOPASS:-0} -ne 0 ]] && echo -e "‼️ WARNING: You are creating a CA \
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

info "Using '$(basename "$templateCA")' as a template for your CA certificate:\n"
info "Replacing fields with configured options with distinguising details from your local session as defaults/fallback values.\n"

subjstr="/CN=$subj_cn/O=$subj_o/OU=$subj_ou/C=$subj_c/"

x509args=(-in "$templateCA" -x509toreq
  -out "$CAtop/$newCAcsr"
  -set_subject "$subjstr"
  -key "$CAtop/private/$newCAkey"
	-copy_extensions copyall
)

[[ -n $CLREXT ]] && x509args+=(-clrext)
[[ -n $EXTFILE ]] && x509args+=(-extfile "$EXTFILE")
[[ -n $EXTENSIONS ]] && x509args+=(-extensions "$EXTENSIONS")
#[[ -n "$OPENSSL_CONFIG" ]] && x509args+=(-config "$OPENSSL_CONFIG")

openssl x509 "${x509args[@]}"

info "Self-signing newly minted certificate:"

CAargs=(-in "$CAtop/$newCAcsr"
  -verbose
  -out "$CAtop/$newCAcert"
  -subj "$subjstr"
  -notext -rand_serial -utf8
  -days "${VALIDDAYS:-7305}")

if [[ -n $signingCA ]] && [[ -n $signingCA_key ]]; then
  CAargs+=(-cert "$signingCA"
    -keyfile "$signingCA_key"
    -extensions subca_ext)
else
  CAargs+=(-selfsign
    -keyfile "$CAtop/private/$newCAkey"
    -extensions rootca_ext)
fi

[[ -n $CLREXT ]] && CAargs+=(-clrext)
[[ -n $EXTFILE ]] && CAargs+=(-extfile "$EXTFILE")
[[ -n $EXTENSIONS ]] && CAargs+=(-extensions "$EXTENSIONS")
[[ -n $OPENSSL_CONFIG ]] && CAargs+=(-config "$OPENSSL_CONFIG")

openssl ca "${CAargs[@]}"
openssl x509 -in "$CAtop/$newCAcert" -text

echo "☆彡・Success!・☆彡"
echo -e "▶ Sucessfully generated and signed certificate authority at:\n"
echo "$CAtop/$newCAcert"