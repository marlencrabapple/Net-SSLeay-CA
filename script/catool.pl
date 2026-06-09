#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

package newca;

class newca;

use Net::SSLeay::CA::Util;
use Net::SSLeay;
use Path::Tiny;

field $cliopt;

use utf8;
use v5.40;

package newca::cli;

class newca::cli;

use Getopt::Long
  qw(GetOptionsFromArray :config no_ignore_case auto_abbrev passthrough long_prefix_pattern=--?);

method cli : common ($argv = \@ARGV) {
    my %clidest;
    GetOptionsFromArray(
        $argv,
        \%clidest,
        'caroot:s',
        'catop|ca-directory|ca-path:s',
        'subj-cn|cn|commonname:s',
        'subj-o|organization:s',
        'subj-ou|ou|orgunit|organizational-unit-name:s',
        'san-dns|san-domainname|dns|domainname:s',
        'san-email|email:s',
        'san-ip:ip-address|ipaddress:s',
        'country:s',
        'state|province:s',
        'locality:s',
        'client-auth',
        'server-auth',
        'smime',
        'x509-extensions|extensions=s{,}',
        'digest|md',
        'keyalgo|key-algorithm',
        'keybits',
        'issuer-cert|ca-cert|signing-cert|parent-cert:s',
        'issuer-key|ca-key|signing-key|parent-key:s',
        '<>' => sub ($barearg) {
            ...;
        });

        if(lc($clidest{keyalgo}) eq 'rsa') {

        }
        elsif(lc)

        if
    );
}
