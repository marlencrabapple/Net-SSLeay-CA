#!/usr/bin/env bash
[[ "${SBINIT_DEBUG:=${DEBUG:-0}}" -gt 0 ]] && set -x

#setopt NULLGLOB
[[ -n "$SBTOOL_ROOT" ]] || SBTOOL_ROOT="/etc/sbtool"
# PLATFORM_KEY="$SBTOOL_ROOT/"PK.{key,pem}
# MACHINEOWNER_KEY=""

export NAME

if [[ -z "$1" ]]; then
    echo -n "Enter shared common name value for PK, KEK and db:"
    read NAME
else
    NAME="$1"
fi

SUBJBASE=$(perl -Mv5.40 -Mutf8 -MSys::Hostname -MData::Dumper -e 'warn Dumper([\@ARGV, $ENV{NAME}, $ENV{SBINIT_SUBJCN}, shift @ARGV, hostname]); my $cn = ($ENV{NAME} || $ENV{SBINIT_SUBJCN} || shift @ARGV || hostname); my $subj = "/CN=$cn"; my $o = ($ENV{SBINIT_SUBJO} // shift @ARGV); $o and $subj.="O=$o/"; my $ou = ($ENV{SBINIT_OU} // shift @ARGV); $ou and $subj .= "OU=$ou"; say $subj' "$@")

echo "$SUBJBASE"

[[ -z "$OUTDIR" ]] && OUTDIR="$SBTOOL_ROOT/${SUBJBASE:=${NAME:-${SUBJBASE:-$(hostname)}}}_$(date +%s)"

mkdir -p "$OUTDIR"

mkdirout="$(
    perl -Mv5.40 -MCwd=abs_path -MData::Dumper -MPath::Tiny \
        -e 'my $path = path($ARGV[0] =~ s/\//_/rg)->mkdir; warn Dumper(\@ARGV, $?, $!, $path) or $?; say $path;' \
        "$OUTDIR" || exit $?
)"

# for kp in PK KEK db; do
#   CERTFILE=$(${$kp\_CERTFILE:-./${kp}.crt})
# done
echo "$mkdirout"
mkdir -p "$mkdirout/priv"
(
    cd "$mkdirout" || exit
    # for kp in PK KEK db; do
    #   CERTFILE=$(${$kp\_CERTFILE:-./${kp}.crt})
    # done

    PK_KEYFILE="./priv/PK.key"
    PK_CERTFILE="./PK.crt"

    [[ ! -f "$PK_KEYFILE" ]] || [[ ! -f "$PK_CERTFILE" ]] &&
        openssl req -new -x509 -newkey rsa:4096 \
            -subj "$SUBJBASE PK/" -keyout "$PK_KEYFILE" \
            -out "$PK_CERTFILE" -days 3650 -nodes -sha256

    openssl req -new -x509 -newkey rsa:2048 -subj "$SUBJBASE KEK/" \
        -keyout priv/KEK.key -out KEK.crt -days 3650 -nodes -sha256

    openssl req -new -x509 -newkey rsa:2048 -subj "$SUBJBASE db/" -keyout priv/db.key \
        -out db.crt -days 3650 -nodes -sha256

    openssl x509 -in PK.crt -out PK.cer -outform DER
    openssl x509 -in KEK.crt -out KEK.cer -outform DER
    openssl x509 -in db.crt -out db.cer -outform DER

    GUID="$(uuidgen)"
    echo "$GUID" >myGUID.txt

    cert-to-efi-sig-list -g "$(<myGUID.txt)" PK.crt PK.esl
    cert-to-efi-sig-list -g "$(<myGUID.txt)" KEK.crt KEK.esl
    cert-to-efi-sig-list -g "$(<myGUID.txt)" db.crt db.esl

    [[ -f "noPK.esl" ]] &&
        mv noPK.esl "SENSITIVE_noPK.$(perl -e 'use Time::HiRes; printf "%d%d" Time::HiRes::gettimeofday').esl"

    touch noPK.esl

    sign-efi-sig-list -g "$(<myGUID.txt)" \
        -k priv/PK.key -c PK.crt PK PK.esl PK.auth
    sign-efi-sig-list -g "$(<myGUID.txt)" \
        -k priv/PK.key -c PK.crt PK noPK.esl noPK.auth
    sign-efi-sig-list -g "$(<myGUID.txt)" \
        -k priv/PK.key -c PK.crt KEK KEK.esl KEK.auth
    sign-efi-sig-list -g "$(<myGUID.txt)" \
        -k priv/KEK.key -c KEK.crt db db.esl db.auth

    chmod 0600 priv/*.key
)

echo "Keys generated in: $mkdirout"
