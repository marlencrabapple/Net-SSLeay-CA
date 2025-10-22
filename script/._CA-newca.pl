#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';
use lib 'lib';

package Net::SSLeay::CA::newca;

class Net::SSLeay::CA::newca
  : isa(Net::SSLeay::CA::Exec);

# : isa(Net::SSLeay::CA::Base);

use utf8;
use v5.40;

use Net::SSLeay;
use Getopt::Long;
use Net::Domain;
use List::Util 'any';

# inherits '$outh';
# inherits '$errh';

#does(Net::SSLeay::CA::Exec);
# field $fffffffffffffff



field $argv    : param = \@ARGV;
field $clispec : param(setup);
field $cliopt  : param(dest);
field $env;



sub writeh ( $line, $handle = *STDIN, %opts ) {
    chomp $line;
    say $handle->$ $line;
    $line;
}

method $outh ( $line, %opts ) {
    writeh( $line, %opts );
    push @$out, $line;
}

method $errh ( $line, %opts ) {
    writeh("❌️ $line");
    push @$out, $line;
}


method genpkey ( $outf, $type, %opts ) {

$self->genpkey_pass($$opts{pwlen}, %opts) unless $opts{no_pass} // $opts{pass}

    run3(
        [
            qw(openssl genpkey -algorithm), $type,
            '-pkeyopt',                     join ':',
            %opts{bits},                    '-pass',
        ]
    );
}

method genpkey_pass( $len, %opts ) {
    my @args = ($len);

    unshift @args, '-s', if any { $_ } @opts{qw'alnum simple alpha'};

    run3( [ 'pwgen', @args ], \undef, $outh, $errh );
}

method x509toreq ( $certin, %opts ) {

}

method signCA ( $unsigned, $sigcert, %opts ) {

}

method $run (%opts) {

}

method run : common ($argv = \@ARGV, $dest =  {}, %opts) {
  my ($self, $res) = $class->new(argv => $argv, dest => $dest)->$run(%opts)
  Net::SSLeay::CA::Base::dmsg({ self => $self, res => $res, argv => $argv, opts => \%opts dest => $dest})
}
