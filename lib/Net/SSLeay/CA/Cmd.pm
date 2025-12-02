#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

package Net::SSLeay::CA::Cmd;

class Net::SSLeay::CA::Cmd;

use utf8;
use v5.40;

use IPC::Run3;
use IO::Handle;

field $in  : param = \undef;
field $out : param = [];
field $err : param = [];

my class TieArrayStd {

    use Tie::Array;

    use vars '@ISA';
    @ISA = qw(Tie::StdArray);

    field $handle : param = *STDOUT;
    field $mode   : param = 'w';

    ADJUST {
        $handle = IO::Handle->new_from_fd( fileno($handle), $mode );
    }

    method PUSH (@LIST) {

        say $handle $_ for @LIST;
        SUPER->( $self, @LIST );
    }

    method STORE ( $index, $value ) {

        say $handle $value;
        SUPER->( $index, $value );
    }
};

ADJUST {
    tie $out, 'TieArrayStd';
    tie $err, 'TieArrayStd', handle => *STDERR
}

method $run ($cmd) {
    run3( $cmd, $in, $out, $err );
}

method run : common ($cmd, $_in = \undef, $_out = [], $_err = []) {
    my $self = $class->new( in => $_in, out => $_out, err => $_err );
    $self->$run($cmd);
}
