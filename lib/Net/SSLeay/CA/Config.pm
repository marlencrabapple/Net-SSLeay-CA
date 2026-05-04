use Object::Pad ':experimental(:all)';

package Net::SSLeay::CA::Config;
role Net::SSLeay::CA::Config : does(Net::SSLeay::CA::Base);

use utf8;
use v5.40;

use Net::SSLeay::CA::Base;

field $env    : reader;
field $cliopt : reader;

ADJUSTPARAMS($params) {
   # dmsg( { self => $self, params => $params } )
}

method load {
    dmsg( { self => $self } );
}
