#!/usr/bin/env perl
package dist;

use v5.40;
use re 'strict';
use Path::Tiny;
use TOML::Tiny qw'from_toml to_toml';
use IPC::Nosh;
use IO::Handle::Common;

my $verbose = $ENV{VERBOSE};
my $debug = $ENV{DEBUG};
my $config_file = path("minil.toml");
my $config      = from_toml( $config_file->slurp_utf8 );
my $package     = ( $$config{name} =~ s/-/::/gr );
my $archive;
my $version;
my $trial = grep { $_ eq '--trial' } @ARGV;
my $has_suffix;
my $dist_suffix;
$dist_suffix = 'TRIAL' if $trial;
dmsg $config, $package, $trial, $dist_suffix;

sub make_dist($dist, %opt){
    my  ($archive, $version, $has_suffix);
my $test = 0;

my $run  = run(
    [ qw'minil dist', @ARGV ],
    out => sub ( $line, @ ) {
        $test++;
        my $archive_re = qr /^Wrote (($dist)-(.+?)(?:-(TRIAL))?\.tar\.gz)$/;

        dmsg $line, $dist, $archive_re, $test; #\@arg;

        if ($verbose) {
            my $say = $debug ? __LINE__ . ": $line" : $line;
            say $say;
        }

        # TODO: Add functionality to remove callback when no longer needed 
        ( $archive, undef, $version, $has_suffix ) = ( $line =~ $archive_re ) unless $archive && $version;
    },
    err => sub ( $line, @ ) { say STDERR $line if $verbose },
    autochomp => 1
);

dmsg $archive, $version, $has_suffix, $test;

say join "\n", $run->err->lines_utf8 if $verbose;

fatal( ( join " ", $run->cmd->@* )
    . " exited with non-zero status: "
      . $run->status )
  if $run->status != 0;

fatal "Could not parse archive name from '"
  . ( join " ", $run->cmd->@* )
  . "' output."
  unless $archive && $version;

  ($archive, $version, $has_suffix)
}

sub rename_archive {
    ...;
}

sub upload_archive {
    ...;
}

( $archive, $version, $has_suffix ) =
  make_dist( $$config{name}, trial => $trial );

dmsg( $archive, $version, $has_suffix );

$archive = path($archive);

if (
    my $moved =
      $has_suffix || !$dist_suffix
    ? $archive
    : $archive->move(
        $archive->basename(qr/\.tar\.gz$/) . "-$dist_suffix.tar.gz"
    )
  )
{
    success "Wrote $moved";
    exit 0;
}
else {
    fatal "Something went wrong. ($?)";
    dmsg $archive, $moved;
}

