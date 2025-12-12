subjcn="$1"
san="$@"
cnslug=$(perl -e -Mv5.40 -e 'say $ARGV[0] =~ s/[\s]+/-/rxg =~ s/[^a-z0-9_-]//rxgi' "$subjcn")

echo "▶ Generating private key..."
paramout="ecp-$(date +%s).pem"
openssl genpkey -genparam -algorithm EC -out "$paramout" \
               -pkeyopt ec_paramgen_curve:secp384r1 \
               -pkeyopt ec_param_enc:named_curve

openssl genpkey -paramfile "$paramout" -out "$cnslug-key.pem"

echo "▶ Creating CSR..."
openssl req -new -subj "/C=US/CN=The Internette" \
            -addext "subjectAltName = DNS.0:the.internette.online,DNS.1:*.the.internette.online" \
	    -keyfile "$cnslug-key.pem" -out "$cnslug-csr.pem"
