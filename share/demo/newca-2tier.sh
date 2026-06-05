#!/usr/bin/env ksh

( set -x -o functrace
	export CATOP="/home/nameless/.local/ca"
	export SUBJ_CN="nameless@cincotuf.lan Root CA RSA G1"

  env OPENSSL_CONFIG=/home/nameless/Net-SSLeay-CA.1/share/root_ca.cnf \
   DEBUG=1 \
   KEYBITS=8192 \
   ~/Net-SSLeay-CA.1/script/newca.sh 2>&1 \
    | tee -a "$(slugify "$SUBJ_CN-newca.sh-$(date +%s)").txt";


	export ISSUER_SUBJCN="$SUBJ_CN"
	SUBJ_CN="${ISSUER_SUBJCN/Root/Intermediate}"

	env CATEMPLATE=/home/nameless/Downloads/r12.pem \
	 CA_CERT="$CATOP/nameless@cincotuf.lan_Root_CA_RSA_G1.pem" \
	 CA_KEY=$CATOP/private/nameless@cincotuf.lan_Root_CA_RSA_G1-key.pem \
	 OPENSSL_CONFIG=/home/nameless/Net-SSLeay-CA.1/share/sub_ca.cnf        \
	 DEBUG=1 \
	 KEYBITS=4096 \
	 /home/nameless/Net-SSLeay-CA.1/script/newca.sh 2>&1 \
	  | tee -a "$(slugify "$SUBJ_CN-newca.sh-$(date +%s)").txt";
)