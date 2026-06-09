#!/usr/bin/env perl
package dist;
use v5.40;

use Path::Tiny;
use TOML::Tiny qw'from_toml to_toml';
use IPC::Nosh;
use IO::Handle::Common;

my $verbose = $ENV{VERBOSE};
my $config_file = path("minil.toml");
my $config      = from_toml( $config_file->slurp_utf8 );
my $package     = ( $$config{name} =~ s/-/::/gr );
my $dist_archive;
my $version;
my $trial = grep { $_ eq '--trial' } @ARGV;
my $has_suffix;
my $dist_suffix;
$dist_suffix = 'TRIAL' if $trial;
dmsg $config, $package, $trial, $dist_suffix;

sub make_dist($dist, %opt){
    my  ($archive, $version, $has_suffix);

my $run = run (
    [ qw'minil dist', @ARGV ],
    out => sub {    # 'Wrote Net-SSLeay-CA-0.01.tar.gz',
        my $line = shift;
            say $line if $verbose;
            my ( $archive, $version, $has_suffix ) =
              $line =~ /^Wrote ($dist-(.+?)(-TRIAL)?\.tar\.gz)$/g;
    },
    err       => sub { my $line = shift; say $line if $verbose },
    autochomp => 1
);
# foreach my ($line) ($run->out->lines_utf8) {
#             say $line if $verbose;
#         my ( $archive, $version, $has_suffix ) =
#           $line =~ /^Wrote ($dist-(.+?)(-TRIAL)?\.tar\.gz)$/g; #{
            
#           #}}

say join "\n", $run->err->lines_utf8 if $verbose;

# dmsg $run;

fatal( ( join " ", $run->cmd->@* )
    . " exited with non-zero status: "
      . $run->status )
  if $run->status != 0;

  ($archive, $version, $has_suffix)
}

($dist_archive, $version, $has_suffix) = make_dist($$config{name}, trial => $trial) ;

dmsg( $dist_archive, $version, $has_suffix );

# dmsg $run#;

path($dist_archive)->move("$dist_archive-$dist_suffix") unless $has_suffix || !$dist_suffix;
