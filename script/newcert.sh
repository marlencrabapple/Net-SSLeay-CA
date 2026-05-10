#!/usr/bin/env ksh
set -Ce

[[ ${DEBUG:-0} -gt 0 ]] && set -x -ofunctrace

subjcn_def="$(whoami)@$(hostname)"
readonly subjcn_def

function openssl_genpkey {
	# typeset -a argv=("$@")
	typeset -a openssl_genpkey_arg=()

	typeset fnbase="$1"
	shift

	typeset -a pkeyopt=("$@")

	if [[ ${pkeyopt[*]:0:1} == 'RSA' ]]; then
		typeset bits="${pkeyopt[*]:1:1}"

		[[ -z $bits ]] && bits="${PKEY_BITS:-4096}"

		openssl_genpkey_arg+=(--algorithm "RSA" --pkeyopt "rsa_keygen_bits:$bits")

	elif [[ ${pkeyopt[*]:0:1} == 'EC' ]]; then
		ec_paramfile="${fnbase}_ec_params"
		ec_paramgen_curve="${pkeyopt[*]:1:1}"

		[[ -z $ec_paramgen_curve ]] &&
			ec_paramgen_curve="${PKEY_CURVE:-secp384r1}"

		openssl genpkey -genparam \
			-algorithm EC \
			-out "$ec_paramfile" \
			-pkeyopt "ec_paramgen_curve:$ec_paramgen_curve" \
			-pkeyopt ec_param_enc:named_curve

		openssl_genpkey_arg+=(--paramfile "$ec_paramfile")
	fi

	openssl genpkey -verbose "${openssl_genpkey_arg[@]}" \
		-out "$fnbase-key.pem"
}

function openssl_req {

	typeset fnbase="$1"
	typeset outfn="$2"

	typeset fnbase_noext="${fnbase%.pem}"
	# typeset subjfmt="/C=%s/CN=%s/"

	typeset subjstr

	subjstr="$(printf "/C=%s/CN=%s/" \
		"${SUBJ_C:-US}" \
		"${SUBJ_CN:-"$subjcn_def"}")"

	typeset -a openssl_req_arg=(
		-new
		-subj "$subjstr"
		-addext "subjectAltName=$SAN"
		-key "${fnbase_noext}-key.pem"
		-out "$outfn")

	openssl req "${openssl_req_arg[@]}"
}

function openssl_x509_req {
	typeset csrfile="$1"
	# typeset keyfile="$2"
	typeset certout="${3:-"${csrfile%%.pem}"-cert.pem}"
	# typeset cacert="$4"

	typeset cacert="${ISSUER_CERT:-"${CA_CERT:-"$CA"}"}"
	typeset cakey="${ISSUER_CERT:-"${CA_KEY:-"$CAKEY"}"}"

	typeset -a openssl_x509_arg=(
		-req
		-in "$csrfile"
		-copy_extensions copy
		# -key "$keyfile"
		-out "$certout")

	# openssl x509 -req -in "$csrfile" -copy_extensions copy -key "$fnbase-key.pem" -out "$fnbase.pem"

	[[ -n $cacert ]] &&
		[[ -n $cakey ]] &&
		openssl_x509_arg+=(-CA "$cacert" -CAkey "$cakey")

	openssl x509 "${openssl_x509_arg[@]}"
}

echo "▶ Creating x509v3 leaf certificate..."
echo ""

pkeyalgo="${PKEY_ALGO:-RSA}"

_fnbase="${1:-$(slugify "${SUBJ_CN:-"$subjcn_def"}")}"

fnbase="$(perl -Mv5.40 -MList::Util=any -e 'my @san = (split /,/, $ENV{SAN}); my $c = scalar @san; my $fbase = shift @ARGV; $c-- if any { $_ =~ /^[^:]+:$ENV{SUBJ_CN}$/ } @san; $fbase .= "+$c" if $c >= 1; say $fbase' "$_fnbase")"

>&2 echo "▶ Generating private key material... ($pkeyalgo:$PKEY_BITS)"
openssl_genpkey "$fnbase" "$pkeyalgo" "$PKEY_BITS"
>&2 echo "  Wrote private key to '${fnbase-key.pem}' 🔚"

>&2 echo "▶ Generating CSR..."
csrfile="$fnbase-csr.pem"
>&2 echo "  Wrote private key to '${fnbase-key.pem}' 🔚"

openssl_req "$fnbase" "$csrfile"

>&2 echo "▶ Signing CSR..."
openssl_x509_req "$csrfile" "${fnbase}-key.pem" "${fnbase}.pem"
>&2 echo "  Wrote certificate to '${fnbase}.pem' 🔚"

>&2 echo "▶ Output certificate info:"
echo "======="
openssl x509 -in "${fnbase}.pem" -text
echo "======="
echo ""
