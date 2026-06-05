#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

use lib 'lib';

package santest;

class santest : isa(Net::SSLeay::CA::Certificate::SAN);

use utf8;
use v5.40;

use IO::Handle::Common;

field $ip;
field $dns;
field $email;
field $uri;

field $san;

ADJUSTPARAMS($params) {
    $san = Net::SSLeay::CA::Certifcate::SAN->new();
    dmsg $san;
}

method $run {
    ...;
}

method run : common ( $argv = \@ARGV, %opts ) {
    my $self = $class->new( %$argv, %opts );
    dmsg $self;
    $self->$run;
}

package main;

santest->run

  #santest->new(@ARGV)
