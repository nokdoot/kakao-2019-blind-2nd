#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;
use Data::Dumper qw(Dumper);

my %capital_of = (
    Bangladesh => 'Dhaka',
    Tuvalu     => 'Funafuti',
    Zimbabwe   => 'Harare',
    Eritrea    => 'Asmara',
    Botswana   => 'Gaborone',
);

my %africa = %capital_of{'Zimbabwe', 'Eritrea', 'Botswana'};
print Dumper \%africa;
