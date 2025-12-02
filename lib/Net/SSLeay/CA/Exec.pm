use Object::Pad ':experimental(:all)';

package Net::SSLeay::CA::Exec;

class Net::SSLeay::CA::Exec : does(Net::SSLeay::CA::Base);

use utf8;
use v5.40;

use vars '@EXPORT';

@EXPORT = qw(exec);
use parent 'Exporter';

use IPC::Run3;
use List::Util 'any';
use Stream::Buffered;

my class Run : does(Net::SSLeay::CA::Base) {

    # field $cmd_aref : param(cmd);
    # field $outbuff  : param = [];
    # field $errbuff  : param = [];
    # field $status;
    # field $err;
};

field $cmd_aref : param(cmd);
field $outbuff  : param = [];
field $errbuff  : param = [];
field $status;
field $err;

sub writeh ( $line, $handle = *STDOUT, %opts ) {
    state %buff = ();

    $opts{buff} = Stream::Buffered->new
      if $opts{buff} && !ref $opts{buff} && $opts{buff} eq 1;

# TODO: Check if does various file handle methods (seek in particular seemed important to a useful Tie implementation)
    $buff{ $opts{buff} } = $opts{buff} if $opts{buff} && ref $opts{buff};

    $line = "《Info》" if any { $opts{$_} == 1 } qw(info notice help);
    $line = "▶ $line"
      if any { $opts{$_} == 1 } qw(plain say print arrow right_arrow);
    $line = "❌️ $line " if any { $opts{$_} == 1 } qw(error fatal die);
    $line = "‼️ $line"  if any { $opts{$_} == 1 } qw(warn warning danger);

    say $handle->$ $line unless $opts{quiet};
    $opts{buff};
}

sub fatal ( $err, $status = 255, %opts ) {
    writeh( $err, *STDERR, fatal => 1, %opts );
    exit $status;
}

method $outh ( $line, %opts ) {
    writeh( $line, buff => Stream::Buffered->new, %opts );
    push @$outbuff, $line;
}

sub info ( $msg, %opts ) {
    writeh( $msg, info => 1, %opts );
}

method $errh ( $line, %opts ) {
    writeh( $line, buff => Stream::Buffered->new, warn => 1, %opts );
    push @$errbuff, $line;
}

method $_ ( $cmd_aref, $stdin, $stdout, $stderr, %opts ) {
    run3( $cmd_aref, $stdin // \undef, $stdout = $outh, $stderr = $errh,
        %opts );
}

method exec : common (
  $cmd_aref,
  $inh = \undef,
  $outh = sub ( $self, $line ) {
  $self->$outh( $line, buff => Stream::Buffered->new );
  },
  $errh = sub ( $self, $line ) {
  $self->$errh( $line, buff => Stream::Buffered->new );
  },
  %opts
  )
{
    $opts{reinit} //= 1;

    state $self;
    if ( !$self || $opts{reinit} ) {
        $self = Net::SSLeay::CA::Exec->new(
            cmd => $cmd_aref,
            in  => $inh,
            out => $outh,
            err => $errh
        );
    }

    my $run = $self->$_( $cmd_aref, $inh, $outh, $errh );

    fatal( "Unknown error occured while trying to run external command:\n"
          . join " @$cmd_aref" );
}
