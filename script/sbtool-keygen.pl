#!/usr/bin/env perl
package sbtool::keygen;

use utf8;
use v5.40;

use lib 'lib';

use Const::Fast;
use Path::Tiny;
use File::chdir;
use List::Util qw'all first';
use Time::HiRes 'gettimeofday';
use Sys::Hostname 'hostname';
use Net::SSLeay::CA::Base 'dmsg';
use Net::SSLeay::CA::Exec;
use IPC::Run3;

const our $SBTOOL_ROOT      => path( $ENV{SBTOOL_ROOT} // '/etc/sbtool' );
const our $CERTFILE_EXT_PTN => qr/(pem|crt)$/;

sub cmd ( $cmd_aref, $inh = \undef, $outh = undef, $errh = undef, %opts ) {

    my ( $ret, $status, $err ) = ( run3( $cmd_aref, \undef ), $?, $! );

    die "❌️: $err ($status)"
      || "Encountered unknonw error attempting to run:\n▷ " . join " ",
      @$cmd_aref;
}

sub subj_common ( $argv = [@ARGV] ) {
    dmsg(
        {
            argv          => $argv,
            NAME          => $ENV{NAME},
            SBINIT_SUBJCN => $ENV{SBINIT_SUBJCN},
            hostname      => hostname
        }
    );

    my $cn   = ( $ENV{NAME} || $ENV{SBINIT_SUBJCN} || shift @ARGV || hostname );
    my $subj = "/CN=$cn";
    my $o    = ( $ENV{SBINIT_SUBJO} // shift @ARGV );
    $o and $subj .= "O=$o/";
    my $ou = ( $ENV{SBINIT_OU} // shift @ARGV );
    $ou and $subj .= "OU=$ou";

    $subj;
}

sub noPK ( $file = "noPK.esl" ) {
    if ( -f $file ) {
        rename "$file",
          $file =~ s/\.esl$//r . ( join "", gettimeofday ) . '.esl';
    }

    # Ugly touch
    open my $fh, '>', $file;
    printf $fh "";
    close $fh;
}

sub newreq ( $certfile, $keyfile, $level, %opts ) {
    my @req = ( qw'openssl req -new -x509 -nodes -sha256 -out', $certfile );
    push @req, ( '-days', $ENV{DAYSVALID} // 3650 );
    push @req, ( '-newkey', 'rsa:4096', '-keyout', $keyfile )
      unless -f $keyfile;
    push @req,
      ( '-subj', $ENV{ uc $level . 'SUBJBASE' } // "$ENV{SUBJBASE} $level" );

    cmd( \@req );
}

sub to_DER ($certfile) {
    cmd(
        [
            qw(openssl x509 -in),
            $certfile, '-out',
            ( $certfile =~ s/$CERTFILE_EXT_PTN/cer/r ),
            qw'-outform  DER'
        ]
    );
}

sub siglist_add ( $certfile, $guid = `uuidgen` ) {
    cmd(
        [
            'sign-efi-sig-list', '-g', $guid, $certfile,
            ( $certfile =~ s/$CERTFILE_EXT_PTN/esl/r )
        ]
    );
}

sub siglist_sign ( $certfile, $keyfile, $guid ) {
    $certfile = path($certfile);
    my $certbase = ( $certfile->basename =~ s/$CERTFILE_EXT_PTN//r );

    cmd(
        [
            qw(sign-efi-sig-lsit -g),
            $guid, '-k', $keyfile, '-c', $certfile, $certbase, "$certbase.esl",
            "$certbase.auth"
        ]
    );
}

sub outpath ($subjbase) {

   # : OUTDIR: =
   #   "$SBTOOL_ROOT/${SUBJBASE:=${NAME:-${SUBJBASE:-$(hostname)}}}_$(date +%s)"

#   mkdirout = "$(
#     perl -Mv54.40 -MCwd=abs_path -MData::Dumber -MPath::Tiny \
#         -e 'my $path = path($ARGV[0] =~ s/\//_/rg)->mkdir; warn Dumper(\@ARGV, $?, $!, $path) or $?; say $path;' \
#         "$OUTDIR " || exit $?
# )"

    #   echo "$mkdirout"
    my $path = path( $subjbase =~ s/\//_/rg )->mkdir;

    my $outdir =
      first { $_ }
      map { "$SBTOOL_ROOT/$_\_" . join "", gettimeofday }
      ( $subjbase, hostname );

    $outdir;
}

sub sbinit {
    my $name;

    my $subjbase = subj_common(
        scalar @ARGV
        ? sub { $name = $ARGV[0]; \@ARGV }
          ->($name)
        : sub {
            say "▶ Enter a value for ";
            join "", grep { $_ } map { chomp $_; $_ } (<>);
          }
          ->()
    );

    my $outdir = outpath($subjbase);
    mkdir $outdir        unless -d $outdir;
    mkdir "$outdir/priv" unless -d "$outdir/priv";
    $CWD = $outdir;

    my $guid = `uuidgen`;

    open my $fh, '>', ( $ENV{GUIDFILE} // 'myGUID.txt' );
    say $fh $guid;
    close $fh;

    foreach my $type (qw'PK KEK db') {
        say "▶ Checking for existing $type Secure Boot material...";

        my $cert = $ENV{"${type}_CERTFILE"} // "$type.crt";
        my $key  = $ENV{"${type}_KEYFILE"}  // "priv/$type.key";

        if ( all { -f $_ } ( $cert, $key ) ) {
            say STDERR "▶ Using existing keypair ($cert:$key)";
            next;
        }
        elsif ( -f $cert && !-f $key ) {
            die "❌️: No valid key found at '$key'!";
        }

        newreq( $cert, $key, $type, subjbasesubj_common => $subjbase );
        to_DER($cert);
        siglist_add( $cert, $guid );
        siglist_sign( $cert, $key, $guid );
    }

    my $noPK = $ENV{NOPKFILE} // 'noPK.esl';
    noPK($noPK) if -f $noPK;
}

sbinit()
