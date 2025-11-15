#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package CA;

use lib 'lib';

class CA : isa(Net::SSLeay::CA);

#inherit Net::SSLeay::CA '$env';

use utf8;
use v5.40;

use Getopt::Long qw'GetOptionsFromArray :config  auto_abbrev';

use Net::SSLeay::CA::Util;

field $argv = [];
field $cliopts : param(dest) = {};

method $run (%opts) {

}

method run : common ($argv = \@ARGV, $dest = {}, %opts) {
    GetOptionsFromArray( $argv, $dest, 'config=s', );
    my $app = $class->new( dest => $dest, argv => $argv, %opts );
    my $res = $app->$run;

    ( $app, $res );

}

package main;

CA->run( \@ARGV )
