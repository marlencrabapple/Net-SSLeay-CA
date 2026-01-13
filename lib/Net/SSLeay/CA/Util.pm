use Object::Pad ':experimental(:all)';

package Net::SSLeay::CA::Util;

role Net::SSLeay::CA::Util;

use utf8;
use v5.40;

#use parent 'Exporter';
use Const::Fast;
use List::Util 'first';
use Net::Domain   ();
use Sys::Hostname ();
use IPC::Nosh::Common;

#use Syntax::Keyword::Dynamically;

#use vars '@EXPORT';
#@EXPORT = qw(user_faux_mail hostfqdn domainname make_anonymous __pkgfn__);

method user_faux_mail : common {
    first { /\.[^.]+$/ } @Net::Domain::[qw(hostfqdn domainname)];
}

method hostname : common {
    const our @dispatch => (
        'Net::Domain'   => [qw(hostdomain hostname hostfqdn)],
        'Sys::Hostname' => [qw(hostname)],

        # 'Sys::Hostname::Long' => [qw(hostname_long)]
    );

    my @domain;

    foreach my ( $package, $subname ) (@dispatch) {
        foreach my $subname (@$subname) {
            my $fqsub = \&{ $package . '::' . $subname };
            push @domain, $fqsub->();
        }
    }
    my $fqdn = first { /^.+\.[^\.]+$/ } @domain;
    $fqdn // $domain[0];
}

