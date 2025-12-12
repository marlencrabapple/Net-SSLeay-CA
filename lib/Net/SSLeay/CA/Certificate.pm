use Object::Pad ':experimental(:all)';

package Net::SSLeay::CA::Certificate;

class Net::SSLeay::CA::Certificate;

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
