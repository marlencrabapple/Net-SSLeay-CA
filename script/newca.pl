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
        'subj-cn:s',
        'subj-o:s',
        'subj-ou:s',
        'issuer-cert|ca-cert|signing-cert|parent-cert:s',
        'issuer-key|ca-key|signing-key|parent-key:s',
        '<>' => sub ($barearg) {
            ...;
        }
    );
}
