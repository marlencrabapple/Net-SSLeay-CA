#!/usr/bin/env ksh

[[ "${DEBUG:-0}" -eq 1 ]] && set -x -o functrace
set -o noclobber

# [[ -z "$CATOP" ]] && CATOP="./$(basename "$0")-$(date +%s)"
# [[ -d "$CATOP" ]] && >&2 echo "❌️ '$CATOP' already exists!"
CATOP="./$(basename "$0")-$(date +%s)"
[[ -d "$CATOP" ]] || mkdir -p "$CATOP"

SUBJ_CN="${ROOTCA_SUBJ_CN:-$SUBJ_CN}"
[[ -z "$SUBJ_CN" ]] && SUBJ_CN="$(hostname) Root CA"

export CATOP
export SUBJ_CN

rootca_subjcn_slug="$(slugify "$SUBJ_CN")"

env OPENSSL_CONFIG="${ROOTCA_CNF:-share/root_ca.cnf}" \
  CATOP="$CATOP/rootca" \
  CATEMPLATE="${ROOTCA_TEMPLATE_CERT}" \
	KEYBITS=8192 \
	newca.sh 2>&1 \
	| tee -a "$(slugify "$0-$(date +%s)").txt"

SUBJ_CN="${SUBCA_SUBJ_CN:-${SUBJ_CN//Root/Intermediate}}"

env CATOP="$CATOP/subca" \
  CATEMPLATE="$SUBCA_TEMPLATE_CERT" \
	CA_CERT="$CATOP/rootca/${rootca_subjcn_slug}.pem" \
	CA_KEY="$CATOP/rootca/private/${rootca_subjcn_slug}-key.pem" \
	OPENSSL_CONFIG="${SUBCA_CNF:-${ROOTCA_CNF:-share/sub_ca.cnf}}"     \
	KEYBITS=4096 \
	script/newca.sh 2>&1 \
	| tee -a "$(slugify "$0-$(date +%s)").txt";
