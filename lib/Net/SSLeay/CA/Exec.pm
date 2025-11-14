use Object::Pad ':experimental(:all)';

package Net::SSLeay::CA::Exec;

class Net::SSLeay::CA::Exec : does(Net::SSLeay::CA::Base);

use utf8;
use v5.40;

use List::Util 'first';

field $out     : reader = [];
field $err     : reader = [];
field $status  : reader;
field $exitmsg : reader =
  first { $_->[ scalar @$_ ] } ( $err, $out );

field $cmd  : param;
field $inh  : param = \undef;
field $outh : param : inheritable : mutator = $out;
field $errh : param : inheritable : mutator = $err;

ADJUSTPARAMS($params) {

}

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

# method $exec ( $cmd_aref, %opt ) {

#     my $exec = (
#         class {

#             field $h_aref = {
#                 inh  => $inh,
#                 outh => $outh,
#                 errh => $errh
#             };

#             ADJUSTPARAMS($params) {
#                 foreach my $h ( values @$h_aref ) {
#                     $h =
#                         $h && ref $h =~ /CODE|GLOB/ ? $h
#                       : truthy($h)                  ? undef
#                       :                               \undef;
#                 }

#                 $self->exec if $$params{exec};

#             }

#             # method writeh ( $line, %opt ) {
#             #     chomp $line;
#             # }

#             # method $_outh ($line) {
#             #     chomp $line;
#             #     say $line;
#             #     push @$out, $line;
#             # }

#             method run {
#                 my $run3ret = run3( $cmd, $inh, $outh, $errh );
#                 $self;
#             }

#         }
#     )->new( cmd => $cmd_aref, run => 1, %opt );

#     $self;
# }
