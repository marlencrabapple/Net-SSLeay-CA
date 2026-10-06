use Object::Pad ':experimental(:all)';

package Net::SSLeay::CA::Base;

role Net::SSLeay::CA::Base;

use utf8;
use v5.40;

use Time::HiRes;
use Time::Piece;
use Time::Moment;
use List::Util 'first';
use Syntax::Keyword::Dynamically;
use Const::Fast;    #::Exporter;
use IPC::Nosh;
use IO::Handle::Common;
use Exporter;

use vars qw'@ISA @EXPORT';

use subs qw(dmsg epoch error success);
@EXPORT = qw(dmsg epoch err);

const our $DEBUG        => $ENV{DEBUG} // 0;
const our $S_UNKNOWNERR => 'Unknown fatal error';


sub epoch( $join = '', %opts ) {
    join $join, Time::HiRes::gettimeofday;
}
