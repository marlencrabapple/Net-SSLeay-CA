use Object::Pad ':experimental(:all)';

package Net::SSLeay::CA::Config;
role Net::SSLeay::CA::Config : does(Net::SSLeay::CA::Base);

use utf8;
use v5.40;

use IO::Handle::Common;
use Net::SSLeay::CA::Base;
use TOML::Tiny;
use List::Util 'any';
use File::XDG;
use Text::Xslate;
use Const::Fast;

const our $default_config => [qw'/etc/catool/catool.toml'];
const our $path_key => [
    qw'catop certfile keyfile config req_config parent_certfile parent_keyfile csr'
];

field $toml = TOML::Tiny->new;
field $xs   = Text::Xslate->new;
field $xdg  = File::XDG->new;

field $config_href : accessor(config) = {};

field $config_file : param(file) = [@$default_config];
field $env    : reader : param = \%ENV;
field $cliopt : reader : param = {};

ADJUSTPARAMS($params) {
    my $user_config_dir = $xdg->user_config;

    push @$config_file, path($user_config_dir)->children(qr/\.toml$/);

    foreach my $file (@$config_file) {
        $file = path($file);

        my $config = $toml->decode( $file->slurp_utf8 );

        $config_href->@{ keys %$config } = values %$config;
    }

    # dmsg( { self => $self, params => $params } )
}

method process_section ($ref) {
    if ( ref $ref eq 'HASH' ) {
        foreach my ( $k, $v ) (%$ref) {
            if ( any { $k eq $_ } @$path_key ) {
                $v = $self->make_path( $v, base => $$ref{catop} );
            }
        }
    }
    elsif ( ref $ref eq 'ARRAY' ) {
        foreach my $elem (@$ref) {
            if ( ref $elem ) {
                $self->process_section($ref);
            }
        }
    }
}

method make_path ( $in, %opt ) {
    $in = path($in);

    if ( $opt{base} && $in->is_relative ) {
        $in->relative( $opt{base} );
    }

    $in->absolute;
}

# Presumptive constructor
method load : common (%opt) {
    $class->new(%opt);
}

method from_cli {

}

method from_env {

}

method save {

}
