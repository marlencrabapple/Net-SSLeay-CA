#!/usr/bin/env bash
#(set -x;
#openssl genpkey -algorithm RSA -pkeyopt bits:4096 -pass "pass:$(pass generate -n Net::SSLeay::CA/taargus@pi4u2.lan_Root_CA_RSA-1-key.pem 128; pass show Net::SSLeay::CA/taargus@pi4u2.lan_Root_CA_RSA-1-key.pem | head -n 1)" -out taargus@pi4u2.lan_Root_CA_RSA-1-key.pem; openssl x509 -in -x509toreq -copy_extensions copyall -out taargus@pi4u2.lan_Root_CA_RSA-1.pem -set_subject "/CN=taargus@pi4u2.lan Root CA RSA-1/O=pi4u2.lan/OU=Local User/C=US/" -key taargus@pi4u2.lan_Root_CA_RSA_1-key.pem)
