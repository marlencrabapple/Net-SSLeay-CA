#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';
use lib 'lib';
class CA : isa(Net::SSLeay::CA);

use utf8;
use v5.40;


use Getopt::Long 'GetOptionsFromArray';

use Net::SSLeay::CA::Util;

field $argv = [];
field $cliopts : param(dest) = {};

ADJUSTPARAMS($params) {

}

method run : common ($argv = \@ARGV, $dest = {}, %opts) {
    GetOptionsFromArray( $argv, $dest, 'config=s', 'cacert=s', 'cakey=s', 'catop=s');
    $class->new( dest => $dest, argv => $argv, %opts );
}

package main;

class main;

