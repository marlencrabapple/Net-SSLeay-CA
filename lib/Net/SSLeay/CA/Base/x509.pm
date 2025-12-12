use Object::Pad ':experimental(:all)';

package Net::SSLeay::CA::Base::x509;

class Net::SSLeay::CA::Base::x509 : abstract;

use v5.40;
use utf8;

my class Subject {
    field $cn : param;
    field $o  : param;
    field $ou : param;
};

field $subjectargs : param(subject);
field $subject : reader = { Subject->new(%$subjectargs) };
field $digestalgo;
field $publickey;

#field $privatekey

