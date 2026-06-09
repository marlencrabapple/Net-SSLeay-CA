#!/usr/bin/env perl

use v5.40;

use IPC::Nosh;
use IO::Handle::Common;

my $run = run( [qw'minil dist --trial'] );
fatal( ( join " ", $run->cmd->@* )
    . " exited with non-zero status: "
      . $run->status )
