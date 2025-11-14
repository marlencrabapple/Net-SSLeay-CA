#!/usr/bin/env bash
set -x

sbcred_store="/etc/sbcred/priv"

[[ "$SIGN_KERNEL" ]] && kernel=$1
[[ "$CPIO_IMAGE" ]] && cpio=$2
[[ "${UKI:-1}" ]] && uki=$3

[[ ! -f "$KERNELDESTINATION" ]] || kernel="$KERNELDESTINATION"

keypairs=("$sbcred_store/db.key" "$sbcred_store/db.crt")

for (( i=0; i<${#keypairs[@]}; i+=2 )); do
    key="${keypairs[$i]}" cert="${keypairs[(( i + 1 ))]}"
    
    for _in in "$kernel" "$cpio" "$uki"; do
	[[ -z "$_in" ]] && continue

	out="$_in"

        sbverify --cert "$cert" "$_in"
	err=$?
	
	[[ $err  -ne 0 ]] || continue
        sbsign --key "$key" --cert "$cert" --output "$out.signed" "$_in" || exit $?
	mv "$out.signed" $out
    done
done

