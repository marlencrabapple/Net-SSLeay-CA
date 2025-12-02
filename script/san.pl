#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

use utf8;
use v5.40;

use lib 'lib';

package santest;

class santest : isa(Net::SSLeay::CA::SAN);

field $ip;
field $dns;
field $email;
field $uri;

#field $san;

ADJUSTPARAMS($params) {
    $san = Net::SSLeay::CA::SAN->;
    Net::SSLeay::CA::Base::dmsg($san)
}

method $run {
    ...    #$
}

method run : common ( $argv = \@ARGV, %opts ) {
    my $self = $class->new( %$argv, %opts );
    Net::SSLeay::CA::Common::dmsg( { self => $self } );
    $self->$run;
}

package main;

santest->run

  #santest->new(@ARGV)
