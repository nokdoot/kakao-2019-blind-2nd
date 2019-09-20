#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;
use Data::Dumper;

my @array1 = qw/ 1 2 3 4 6 7 /;

my @array2 = qw/ 1 4 /;

sub intersection_array {
    my ($a, $b) = @_;
    my %count = ();
    for (@$a, @$b) {
        $count{$_}++;
    }
    my @intersection;
    for (keys %count) {
        push @intersection, $_ if $count{$_} > 1;
    }
    @intersection = sort @intersection;
    return \@intersection;
}

sub union_array {
    my ($a, $b) = @_;
    my %set = ();
    for (@$a, @$b) {
        $set{$_} = 1;
    }
    my @union = sort keys %set;
    return \@union;
}

sub difference_array {
    my ($a, $b) = @_;
    my @diff;
    my %count = ();
    for (@$a, @$b) {
        $count{$_}++;
    }
    for (keys %count) {
        push @diff, $_ if $count{$_} == 1;
    }
    @diff = sort @diff;
    return \@diff;
}

my $difference = difference_array(\@array1, \@array2);
my $union = union_array(\@array1, \@array2);
my $intersection = intersection_array(\@array1, \@array2);
say @$difference;
say @$union;
say @$intersection;
