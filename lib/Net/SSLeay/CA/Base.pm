use Object::Pad ':experimental(:all)';

package Net::SSLeay::CA::Base;

role Net::SSLeay::CA::Base;

use utf8;
use v5.40;

use Data::Dumper::Names;
use Time::HiRes;
use Time::Piece;
use Time::Moment;
use List::Util 'first';
use Syntax::Keyword::Dynamically;
use Const::Fast;    #::Exporter;

use parent 'Exporter';
use Exporter 'import';

use vars qw'@ISA @EXPORT';

use subs qw(dmsg epoch error success);

@ISA = qw(Exporter);
@EXPORT = qw(dmsg epoch err);

const our $DEBUG        => $ENV{DEBUG} // 0;
const our $S_UNKNOWNERR => 'Unknown fatal error';

eval "use Devel::StackTrace::WithLexicals" if $DEBUG;

# field $env : param(runenv) : inheritable {
#     (
#         map {
#             my $name = $_;
#             my $val =
#               first { $_ } @ENV{ map { uc "$_$name" } ( 'ca_', '' ) };
#             $name => $val
#         } qw(verbose debug)
#     )
# }
# field $debug : accessor : param = $DEBUG;

APPLY($mop) {
    use utf8;
    use v5.40;

    use Exporter 'import';
    our @EXPORT = @{__PACKAGE__::EXPORT::}
}

ADJUSTPARAMS($param) {
    use utf8;
    use v5.40;

    # our @EXPORT = qw(dmsg epoch err);
}



sub epoch( $join = '', %opts ) {
    join $join, Time::HiRes::gettimeofday;
}

sub dmsg (@msgs) {

    use Syntax::Keyword::Dynamically;
    $DEBUG || return '';

    my @caller = caller 0;

    my $out = "*** " . localtime->datetime . " - DEBUG MESSAGE ***\n\n";

    dynamically $Data::Dumper::Pad    = "  ";
    dynamically $Data::Dumper::Indent = 1;

    $out .=
        scalar @msgs > 1 ? Dumper(@msgs)
      : ref $msgs[0]     ? Dumper(@msgs)
      :                    eval { my $s = $msgs[0] // 'undef'; "  $s\n" };

    $out .= "\n";

    $out .=
      $ENV{DEBUG} && $ENV{DEBUG} == 2
      ? join "\n", map { ( my $line = $_ ) =~ s/^\t/  /; "  $line" } split /\R/,
      Devel::StackTrace::WithLexicals->new(
        indent      => 1,
        skip_frames => 1
      )->as_string
      : "at $caller[1]:$caller[2]";

    say STDERR "$out\n";
    $out;
}

sub err : prototype($;$%) (
    $msg  = ( $! // $S_UNKNOWNERR ),
    $exit = ( $? ? $? >> 8 : 255 ), %opts
  )
{
    dmsg( { exit => $exit, msg => $msg, opts => \%opts } );

    my $errstr = $msg isa 'ARRAY'
      ? join "\n", map {
        my $str = $_ isa 'HASH' ? $$_{msg} : $_;
        $str = $S_UNKNOWNERR if $str =~ /^[0-9]+$/ && $str == 0;
        $str
      } @$msg
      : $msg;

    die "ERROR: $errstr ($exit)";
}

method writeh( $line, $handle, %opt ) {
    state %handle;
    unless ( $handle{$handle} ) {
        $handle{$handle} = IO::Handle->new->fdopen( fileno($handle), "w" );
        binmode $handle, ":encoding(UTF-8)";
    }
    if ( $line isa 'ARRAY' ) {
        say $handle $line for $handle->@*;
    }
    elsif ( !ref $line ) {
        say $handle $line;
    }
}

method outh ($line) {
    $self->writeh( $line, *STDOUT );
}

method errh ($line) {
    $self->writeh( $line, *STDERR );
}

method info ($line) {
    $self->outh("▶ $line");
}

method error ($line) {
    $self->errh("❌️ $line");
}

method fatal ( $line, $status = $? // 255, %opt ) {
    $self->err($line);
    exit $status;
}

method success ($line) {
    $self->outh("⭕️ $line");
}
