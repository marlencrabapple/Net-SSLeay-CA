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

use vars qw'@ISA @EXPORT';

use subs qw(dmsg epoch error success);
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


sub epoch( $join = '', %opts ) {
    join $join, Time::HiRes::gettimeofday;
}
