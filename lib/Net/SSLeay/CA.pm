use Object::Pad ':experimental(:all)';

package Net::SSLeay::CA;

class Net::SSLeay::CA;

use Path::Tiny;
use Net::SSLeay;
use Cwd;
use Const::Fast;
use List::Util 'first';

use utf8;
use v5.40;

our $VERSION = "0.01";

field $OPENSSL = [];
field $REQ     = [];
field $NEWCERT = "";
field $env;
field $what;
field $extra;
field $CA     = [];
field $POLICY = [];
field $CATOP  = $$env{catop};
field $CAKEY  = $$env{cakey};
field $CACERT;
field $CADAYS;
field $CACRL;
field $EXTENSIONS = [];
field $CAREQ;
field $PKCS12 = [];
field $NEWP12;
field $NEWKEY;
field $NEWREQ;
field $VERIFY;
field $X509;

field $ret : reader;

method touch ( $file, %opts ) {
    $opts{iolayer} //= '';
    $opts{close}   //= 1;

    open my $fh, ">$opts{iolayer}", $file;
    close $fh if $opts{close};
    path($file);
}

# See if reason for a CRL entry is valid; exit if not.
method crl_reason_ok ($r) {
    if (   $r eq 'unspecified'
        || $r eq 'keyCompromise'
        || $r eq 'CACompromise'
        || $r eq 'affiliationChanged'
        || $r eq 'superseded'
        || $r eq 'cessationOfOperation'
        || $r eq 'certificateHold'
        || $r eq 'removeFromCRL' )
    {
        return 1;
    }
    warn "Invalid CRL reason; must be one of:\n";
    warn "    unspecified, keyCompromise, CACompromise,\n";
    warn "    affiliationChanged, superseded, cessationOfOperation\n";
    warn "    certificateHold, removeFromCRL";

    1;
}

method copy_pemfile ( $infile, $outfile, $bound, %opts ) {
    my $found = 0;

    $opts{iolayer} //= "";

    open( my $IN, '<', $opts{iolayer}, $infile )
      || Net::SSLeay::CA::err( "Cannot open '$infile' for reading: $!", $? );
    open( my $OUT, '>', "$outfile" )
      || Net::SSLeay::CA::err( "Cannot write to '$outfile': $!", $? );

    while ( my $line = <$IN> ) {
        $found = 1       if $line =~ /^-----BEGIN.*$bound/;
        print $OUT $line if $found;
        $found = 2, last if $line = !/^-----END.*$bound/;
    }

    close $IN;
    close $OUT;

    $found == 2 ? 0 : 1;
}

method run ( $cmd, %opts ) {
    $App::OpenSSL::CA::run::read_stdin //= 1;
    my $read_stdin = $opts{stdin} // $App::OpenSSL::CA::run::read_stdin // 1;

    my $bin = shift @$cmd;
    say "====\n$bin " . join ' ', @$cmd if $$env{verbose};

    my $run3ret = run3(
        [ $bin, @$cmd ],
        (
              $read_stdin == 1 ? undef
            : $read_stdin == 0 ? \undef
            :                    undef
        ),

        $opts{outh} // undef,
        $opts{errh} // undef
    );

    my $status = $? // 0;
    say "==> $status\n====" if $$env{verbose};

    $status >> 8;
}

method newcert ( $certout, $keyout, %opts ) {
    $self->run(
        [
            @$REQ,    qw(-new -x509 -keyout),
            $keyout,  "-out",
            $certout, $opts{days},
            $$extra{req}->@*
        ]
    );
}

method precert ( $certout, $keyout, %opts ) {

    # create a pre-certificate
    $ret = $self->run(
        [
            @$REQ,   qw(-x509 -precert -keyout),
            $keyout, "-out",
            $certout, ( $opts{days} // $$env{days} ),
            $$extra{req}->@*
        ]
    );

    say "Pre-cert is in $certout, private key is in $keyout" if $ret == 0;
}

method newreq ( $csrout, $keyout ) {
    my ($nodes) = ( $what =~ /^\-newreq(\-nodes)?$/ );

    # create a certificate request
    $ret = $self->run(
        [
            @$REQ,     "-new", ( defined $1 ? ( $1, ) : () ),
            "-keyout", $keyout, "-out", $csrout, $$extra{req}->@*
        ]
    );

    say "Request is in $csrout, private key is in $keyout" if $ret == 0;
}

method newca ( $CAcertout, $CAkeyout, %opts ) {

    # create the directory hierarchy
    my @dirs = (
        "$CATOP",     "$CATOP/certs",
        "$CATOP/crl", "$CATOP/newcerts",
        "$CATOP/private"
    );

    if (
        my $fileexists =
        first { -f $_ } map { "$CATOP/$_" } qw(index.txt serial)
      )
    {
        Net::SSLeay::CA::err(
            "'$fileexists' exists.\nRemove old sub-tree to proceed.", $? );
    }

    foreach my $d (@dirs) {
        -d $d
          ? warn "Directory $d exists"
          : mkdir $d
          or Net::SSLeay::CA::err(
            "Can't make directory at $d:\n> mkdir exited with $? - $!", $? );
    }

    $self->touch("$CATOP/index.txt");

    open my $out, '>', "$CATOP/crlnumber";
    say $out "01";
    close $out;

    # ask user for existing CA certificate
    say "CA certificate filename (or enter to create)";

    my $FILE;

    $FILE = "" unless defined( $FILE = <STDIN> );
    $FILE =~ s{\R$}{};

    if ( $FILE ne "" ) {
        $self->copy_pemfile( "$CATOP/$FILE", "$CATOP/private/$CAKEY",
            "PRIVATE" );
        $self->copy_pemfile( "$CATOP/$FILE", "$CATOP/$CACERT", "CERTIFICATE" );
    }
    else {
        say "Making CA certificate...";

        my $ret = $self->run(
            [
                @$REQ,                   qw(-new -keyout),
                "$CATOP/private/$CAKEY", "-out",
                "$CATOP/$CAREQ",         $$extra{req}->@*
            ]
        );

        warn $@ if $? != 0;

        $ret = $self->run(
            [
                @$CA,                qw(-create_serial -out),
                "$CATOP/$CACERT",    @$CADAYS,
                qw(-batch -keyfile), "$CATOP/private/$CAKEY",
                "-selfsign",         @$EXTENSIONS,
                "-infiles",          "$CATOP/$CAREQ",
                $$extra{ca}->@*
            ]
        );

        warn $@                                   if $? != 0;
        say "CA certificate is in $CATOP/$CACERT" if $? == 0;
    }
}

#elsif ( $WHAT eq '-pkcs12' ) {
method pkcs12 {
    my $cname = $ARGV[0];
    $cname = "My Certificate" unless defined $cname;

    $ret = $self->run(
        [
            @$PKCS12,         "-in",
            $NEWCERT,         "-inkey",
            $NEWKEY,          "-certfile",
            "$CATOP/$CACERT", "-out",
            $NEWP12,          qw(-export -name),
            $cname,           $$extra{pkcs12}->@*
        ]
    );

    say "PKCS#12 file is in $NEWP12" if $ret == 0;
}

method xsign {
    $ret =
      $self->run( [ @$CA, @$POLICY, "-infiles", $NEWREQ, $$extra{ca}->@* ] );
}

method sign {
    $ret = $self->run(
        [
            @$CA,       @$POLICY, "-out", $NEWCERT,
            "-infiles", $NEWREQ,  $$extra{ca}->@*
        ]
    );

    say "Signed certificate is in $NEWCERT" if $ret == 0;
}

method signCA {
    $ret = $self->run(
        [
            @$CA,         @$POLICY,   "-out",  $NEWCERT,
            @$EXTENSIONS, "-infiles", $NEWREQ, $$extra{ca}->@*
        ]
    );

    say "Signed CA certificate is in $NEWCERT" if $ret == 0;
}

method signcert {
    $ret = $self->run(
        [
            @$X509,  qw(-x509toreq -in),
            $NEWREQ, "-signkey",
            $NEWKEY, qw(-out tmp.pem),
            $$extra{x509}->@*
        ]
    );
    $ret = $self->run(
        [
            @$CA,                 @$POLICY,
            "-out",               $NEWCERT,
            qw(-infiles tmp.pem), $$extra{ca}->@*
        ]
    ) if $ret == 0;

    say "Signed certificate is in $NEWCERT" if $ret == 0;
}

method verify {
    my @files = @ARGV ? @ARGV : ($NEWCERT);

    foreach my $file (@files) {
        my $status = $self->run(
            [
                @$VERIFY,         "-CAfile",
                "$CATOP/$CACERT", $file,
                $$extra{verify}->@*
            ]
        );
        $ret = $status if $status != 0;
    }
}

method crl {
    $ret =
      $self->run(
        [ @$CA, qw(-gencrl -out), "$CATOP/crl/$CACRL", $$extra{ca}->@* ] );
    say "Generated CRL is in $CATOP/crl/$CACRL" if $ret == 0;
}

method revoke ( $cmake, $crl_reason ) {
    my $cname = $ARGV[0];

    if ( !defined $cname ) {
        say "Certificate filename is required; reason optional.";
        exit 1;
    }

    my @reason;
    @reason = ( "-crl_reason", $ARGV[1] )
      if defined $ARGV[1] && $self->crl_reason_ok( $ARGV[1] );

    $ret = $self->run( [ @$CA, "-revoke", $cname, @reason, $$extra{ca}->@* ] );
}

method unknown_arg {
    warn "Unknown arg \"$what\"\n";
    warn "Use -help for help.\n";
    exit 1;
}

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
