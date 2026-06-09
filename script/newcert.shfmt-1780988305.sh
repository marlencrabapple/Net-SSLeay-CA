#!/usr/bin/env ksh
set -Ce

[[ ${DEBUG:-0} -gt 0 ]] && set -x -ofunctrace

OPENSSL=${OPENSSL:-$(which openssl)}
PERL5BIN="${PERL5BIN:-perl}"
PERL5ARG+=" -Mv5.40 -MIO::Handle::Common -MNet::SSLeay::CA::Util"

export subjcn_def

function hostfqdn {
	"$PERL5BIN" $PERL5ARG -e 'say Net::SSLeay::CA::Util::hostfqdn'
}

function slugify {
	in="$1"
	"$PERL5BIN" $PERL5ARG -e 'say $_ for map { chomp $_; Net::SSLeay::CA::Util::slugify($_, allow => q!@!) } (@ARGV)' \
		"$in"
}

function dmsg {
	in="$@"
	[[ $DEBUG -eq 1 ]] || return 0

	for msg in "${in[@]}"; do
		>&2 echo -e "$msg"
	done
}

function openssl {
	cmd="$1"
	shift
	arg=("$@")

	openssl_out=$("$OPENSSL" "$cmd" "${arg[@]}" 2>&1)
	dmsg "$openssl_out"
}

function openssl_print {
	cmd="$1"
	shift
	arg=("$@")
	"$OPENSSL" "$cmd" "${arg[@]}"

}

function openssl_genpkey {
	# typeset -a argv=("$@")
	typeset -a openssl_genpkey_arg=()

	typeset fnbase="${1%.pem}"
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
	typeset keyfile="${2:-${csrfile%%.pem}-key.pem}"
	typeset certout="${3:-"${csrfile%%.pem}"-cert.pem}"
	# typeset cacert="$4"

	typeset cacert="${ISSUER_CERT:-"${CA_CERT:-"$CA"}"}"
	typeset cakey="${ISSUER_CERT:-"${CA_KEY:-"$CAKEY"}"}"

	typeset -a openssl_x509_arg=(
		-req
		-in "$csrfile"
		-copy_extensions copy
		-out "$certout")

	if [[ -n $cacert ]] && [[ -n $cakey ]]; then
		openssl_x509_arg+=(-CA "$cacert" -CAkey "$cakey")
	else
		openssl_x509_arg+=(-key "$keyfile")
		>&2 echo "▶ No issuing CA provided! Self signing CSR..."
	fi

	openssl x509 "${openssl_x509_arg[@]}"
}

echo "▶ Creating x509v3 leaf certificate..."
echo ""

subjcn_def="$(whoami)@$(hostfqdn)"
SAN="${SAN:-DNS.0:$(hostfqdn)}"

pkeyalgo="${PKEY_ALGO:-RSA}"

_fnbase="${1:-$(slugify "${SUBJ_CN:-"$subjcn_def"}")}"

fnbase="$(env SAN="$SAN" \
	SUBJ_CN="$SUBJ_CN" \
	$PERL5BIN $PERL5ARG -MList::Util=any -e 'my @san = (split /,/, $ENV{SAN}); my $c = scalar @san; my $fbase = shift @ARGV; $c-- if any { $_ =~ /^[^:]+:$ENV{SUBJ_CN}$/ } @san; $fbase .= "+$c" if $c >= 1; say $fbase' "$_fnbase")"

>&2 echo "▶ Generating private key material..."
openssl_genpkey "${fnbase}.pem" "$pkeyalgo" "$PKEY_BITS"
>&2 echo "  Wrote private key to '${fnbase}-key.pem' 🔚"
>&2 echo ""

>&2 echo "▶ Generating CSR..."

csrfile="$fnbase-csr.pem"
openssl_req "$fnbase" "$csrfile"

>&2 echo "  Wrote CSR to '$csrfile' 🔚"
>&2 echo ""

>&2 echo "▶ Signing CSR..."

openssl_x509_req "$csrfile" "${fnbase}-key.pem" "${fnbase}.pem"
openssl_x509_req_exit="$?"

if [[ $openssl_x509_req_exit -eq 0 ]]; then
	>&2 echo "  Wrote certificate to '${fnbase}.pem' 🔚"
	>&2 echo ""

	>&2 echo "⭕️ Successfully generated and signed a leaf certificate! 🎉"

	if [[ "$VERBOSE" ]] || [[ "$DEBUG" ]]; then
		>&2 echo "Certifcate Details:"

		>&2 echo "======="

		# I think I wasnt this to print to stdout...
		openssl_print x509 -in "${fnbase}.pem" -text

		>&2 echo "======="

		>&2 echo ""
	fi
else
	>&2 echo "❌️ Encountered error processing/signing CSR:"
	>&2 echo "▷ $csrfile"
	# echo "Please include this file if you create a bug on our issue tracker:"
	# echo "▷ https://"
fi
