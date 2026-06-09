#!/usr/bin/env ksh

[[ "${DEBUG:-0}" -eq 1 ]] && set -x -o functrace
set -o noclobber
scriptbase="$(basename "$0")"

slugify() {
	in="$1"
	perl -Mv5.40 -MNet::SSLeay::CA::Util \
	-e 'say $_ for map { chomp $_;  Net::SSLeay::CA::Util::slugify($_, allow => q!@!) } (@ARGV)' \
	"$in"
}

logbase="$(slugify "$scriptbase-$(date +s).txt")"

[[ -z "$CA_ROOT" ]] && CA_ROOT="$(pwd)/.catool-root-$(date +%s)"
[[ -d "$CA_ROOT" ]] && >&2 echo "❌️ '$CA_ROOT' already exists!" && exit 1
[[ ! -d "$CA_ROOT" ]] || mkdir -p "$CA_ROOT"

SUBJ_CN="${ROOTCA_SUBJ_CN:-$SUBJ_CN}"
[[ -z "$SUBJ_CN" ]] && SUBJ_CN="$(hostname) Root CA"

export CATOP
export SUBJ_CN

CATOP_BASE="$(slugify "$SUBJ_CN")"
CATOP="$CA_ROOT/$CATOP_BASE"
rootca_subjcn_slug="$CATOP_BASE"

if [[ -z "$CA_CERT" ]] && [[ -z "$CA_KEY" ]]; then
	env OPENSSL_CONFIG="${ROOTCA_CNF:-share/root_ca.cnf}" \
		CATEMPLATE="${ROOTCA_TEMPLATE_CERT}" \
		KEYBITS="${ROOTCA_KEYBITS:-${KEYBITS:-8192}}" \
		newca.sh 2>&1 |
		tee -a "rootca_$logbase"
fi

SUBJ_CN="${SUBCA_SUBJ_CN:-${SUBJ_CN//Root/Intermediate}}"
CATOP_BASE="$(slugify "$SUBJ_CN")"
CATOP="$CA_ROOT/$CATOP_BASE"

env CATEMPLATE="$SUBCA_TEMPLATE_CERT" \
	CA_CERT="$CA_ROOT/${rootca_subjcn_slug}/${rootca_subjcn_slug}.pem" \
	CA_KEY="$CA_ROOT/${rootca_subjcn_slug}/private/${rootca_subjcn_slug}-key.pem" \
	OPENSSL_CONFIG="${SUBCA_CNF:-${ROOTCA_CNF:-share/sub_ca.cnf}}" \
	KEYBITS="${SUBCA_RSA_BITS:-${KEYBITS:-4096}}" \
	newca.sh 2>&1 |
	tee -a "subca_$logbase"
