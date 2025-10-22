#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';
use lib 'lib';
use Net::SSLeay::CA::SAN;

use utf8;
use v5.40;

package santest;
class santest;

field $san;

ADJUSTPARAMS ($params) {
  $san = Net::SSLeay::CA::SAN->new
}

method $run {

}

method run ($argv = \@ARGV, %opts) {

}

package main;

santest->new(@ARGV)
