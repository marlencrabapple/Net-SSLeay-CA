use Object::Pad ':experimental(:all)';

package Net::SSLeay::CA::Util;

class Net::SSLeay::CA::Util : does(Net::SSLeay::CA::Base);

use utf8;
use v5.40;

# use parent 'Exporter';
use Exporter;
use vars '@EXPORT_OK';

@EXPORT_OK = qw(hostfqdn hostname domainname localuser slugify);

use Const::Fast;
use Sys::Hostname qw'';
use List::Util 'first';
use Net::Domain qw'';

sub slugify( $in, %opt ) {
    $opt{replace} //= '_';

# TODO: Append/remove to allow
    my $allow = 'a-z0-9_.+=-';
    $allow .= quotemeta $opt{allow};

    my $ptn = qr/^[${allow}a-z0-9_.+=-]+$/;

    ( $in =~ s/$ptn/$opt{replace}/gir );
}

sub user_faux_mail {
    first { /\.[^.]+$/ } @Net::Domain::{qw(hostfqdn domainname make_anonymous)};
}

sub localuser {
    getpwent;
}

sub hostfqdn {
    Net::Domain::hostfqdn(@_);
}

sub hostname {
    const my @dispatch => (
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


sub domainname {
    Net::Domain::domainname(@_);
}

sub valid_timespan {

}
