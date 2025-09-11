use Object::Pad ':experimental(:all)';

package Net::SSLeay::CA;

class Net::SSLeay::CA : does(Net::SSLeay::CA::Base);

use Path::Tiny;
use Net::SSLeay;
use Cwd;

use Net::SSLeay::CA::Util;

use utf8;
use v5.40;

our $VERSION = "0.01";

ADJUSTPARAMS($params) {

}

__END__

=encoding utf-8

=head1 NAME

Net::SSLeay::CA - It's new $module

=head1 SYNOPSIS

    use Net::SSLeay::CA;

=head1 DESCRIPTION

Net::SSLeay::CA is ...

=head1 LICENSE

Copyright (C) Ian P Bradley.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ian P Bradley E<lt>ian.bradley@studiocrabapple.comE<gt>

=cut

