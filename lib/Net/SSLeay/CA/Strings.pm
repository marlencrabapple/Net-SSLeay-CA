package Net::SSLeay::CA::Strings;
use Const::Fast::Exporter;

use v5.40;
use utf8;

const our $S_HELPUSAGE => qq"
Usage:
    CA.pl -newcert | -newreq | -newreq-nodes | -xsign | -sign | -signCA | -signcert | -crl | -newca [-extra-cmd parameter]
    CA.pl -pkcs12 [certname]
    CA.pl -verify certfile ...
    CA.pl -revoke certfile [reason]
qq"
