#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;
use Data::Dumper qw(Dumper);

use FindBin;
use lib "$FindBin::Bin/../local/lib/perl5";
use List::MoreUtils qw/ uniq /;


my @array = qw / 1 1 1 1 2 3 4 5 5 5 5 1/;
my %hash   = map { $_, 1 } @array;
# or a hash slice: @hash{ @array } = ();
# or a foreach: $hash{$_} = 1 foreach ( @array );

my @unique = sort keys %hash;

say "@unique";

my @test = uniq @array;

say "@test";
