#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

use utf8;
use v5.40;

package santest;

use lib 'lib';

#use Net::SSLeay::CA::SAN;

class santest : isa(Net::SSLeay::CA::SAN);

field $san;

ADJUSTPARAMS($params) {
    $san = Net::SSLeay::CA::SAN->new;
    Net::SSLeay::CA::Base::dmsg($san)
}

method $run {

}

method run ( $argv = \@ARGV, %opts ) {

}

package main;

santest->new(@ARGV)
