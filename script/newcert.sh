#!/usr/bin/env ksh
set -Ce

[[ "${DEBUG:-0}" -gt 0 ]] && set -x -ofunctrace

function openssl_genpkey {
	# typeset -a argv=("$@")
	typeset -a openssl_genpkey_arg=()
	
	typeset fnbase="$1"
	shift

	typeset -a pkeyopt=("$@")

	if [[ "${pkeyopt[*]:0:1}" == 'RSA' ]]; then

    bits="${pkeyopt[*]:1:1}"
		[[ -z "$bits" ]] && bits="${PKEY_BITS:-4096}"

		openssl_genpkey_arg=(--algorithm RSA
			--pkeyopt "rsa_keygen_bits:$bits")
	elif [[ $pkeyalgo == 'EC' ]]; then
		ec_paramfile="${fnbase}_ec_params"

		ec_paramgen_curve="${pkeyopt[*]:1:1}"
		[[ -z "$ec_paramgen_curve" ]] \
		  && ec_paramgen_curve="${PKEY_CURVE:-secp384r1}"

		openssl genpkey -genparam \
			-algorithm EC \
			-out "$ec_paramfile" \
			-pkeyopt "ec_paramgen_curve:$ec_paramgen_curve" \
			-pkeyopt ec_param_enc:named_curve

		openssl_genpkey_arg=(--paramfile "$ec_paramfile")
	fi

	openssl genpkey -verbose "${openssl_genpkey_arg[@]}" \
		-out "$fnbase-key.pem"
}

function openssl_req {
	typeset fnbase="$1"
	typeset outfn="$2"

	openssl req \
		-new \
		-subj "/C=${SUBJ_C:-US}/CN=${SUBJ_CN:-$(whoami)@$(hostname)}" \
		-addext "subjectAltName=$SAN" \
		-key "$fnbase-key.pem" \
		-out "${outfn:-${fnbase}-csr}.pem"
}

function openssl_x509_req {
	typeset csrfile="$1"
	typeset keyfile="$2"
	typeset certout="${3:-${csrfile%.pem}-cert.pem}}"
	# typeset cacert="$4"

	typeset cacert="${ISSUER_CERT:-${CA_CERT:-$CA}}"
	typeset cakey="${ISSUER_CERT:-${CA_KEY:-$CAKEY}}"

	typeset -a openssl_x509_arg=(
		-req
		-in "$csrfile"
		-copy_extensions copy
		-key "$keyfile.pem"
		-out "$certout")

	# openssl x509 -req -in "$csrfile" -copy_extensions copy -key "$fnbase-key.pem" -out "$fnbase.pem"

	[[ -n $cacert ]] &&
		[[ -n $cakey ]] &&
		openssl_x509_arg+=(-CA "$cacert" -CAkey "$cakey")

	openssl x509 "${openssl_x509_arg[@]}"
}

echo "▶ Creating x509v3 certificate..."

pkeyalgo="${PKEY_ALGO:-RSA}"
fnbase="${1:-$(hostname)}"

openssl_genpkey "$fnbase" "$pkeyalgo" "$PKEY_BITS"

csrfile="$fnbase-csr.pem"
openssl_req "$fnbase" "$csrfile"

openssl_x509_req "$csrfile" "${fnbase}-key.pem" "${fnbase}.pem"
