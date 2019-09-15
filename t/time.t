#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;

use Time::HiRes qw / sleep /;

while ( 1 ) {
    my $datestring = localtime();
    say $datestring;
    sleep(0.025);
}
