#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;

my $number = 10;
# Format number with up to 8 leading zeroes
my $result = sprintf("%08d", $number);
# Round number to 3 digits after decimal point
my $rounded = sprintf("%.3f", $number);

say $result;
say $rounded;
