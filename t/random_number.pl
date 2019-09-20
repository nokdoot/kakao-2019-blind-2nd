#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;
use Data::Dumper qw(Dumper);

for ( 1..10 ) {
    my $number = 1 + int rand( 10-1+1 );
    say $number;
}
