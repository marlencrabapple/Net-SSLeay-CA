use Object::Pad ':experimental(:all)';

package Net::SSLeay::CA::SAN;

class Net::SSLeay::CA::SAN : does(Net::SSLeay::CA::Base);

use utf8;
use v5.40;

use URI;
use Socket;

# use Net::SSLeay;
# use Net::SSLeay::CA::Util;

field $uri       = [];
field $ip        = [];
field $email     = [];
field $dns       = [];
field $rid       = [];
field $dirname   = [];
field $othername = [];

ADJUST : params (:$uri, :$ip, :$email, :$dns, :$rid, :$dirname, :$othername ) {

};

# constructor basically, takes an href containing any of the above fields
# method to_SAN : common ($fields, %opts) {
#     my $self =
#       $class->new( %$fields{qw(uri ip email dns rid dirnamee othername)} );
#     $self;
# }

method from_string : common ($str) {

method to_str {
    my $str       = "subjectAltName=";
    my $metaclass = Object::Pad::MOP->for_caller;
    my @fields    = $metaclass->fields;

    my @short_inner = ();

    my $i = 0;

    foreach my ( $k, $v ) ( map { $_->name, $_->value } @fields ) {
        my $vstr = '';
        if ( scalar @$v > 1 ) {
            $k = uc($k) . ".$i";
            my $vstr = join ",", @$v;
        }
        else {
            $vstr = shift @$v;
        }

        $i++;
    }
}
