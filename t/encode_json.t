#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../local/lib/perl5";
use lib '../';
use JSON::XS qw/ decode_json encode_json /;
use Data::Structure::Util qw/ unbless /;

use Command;

my $command = Command->new({
        elevator_id => 0,
        command     => 'UP',
        call_ids    => [1, 2, 3, 4, 5, 6, 7, 8],
    });
#say Dumper (unbless $command);
#say Dumper encode_json $command;

my $jsonner = JSON::XS->new->convert_blessed(1);
say $jsonner->encode( $command );

sub UNIVERSAL::TO_JSON {
    my( $self ) = shift;

    use Storable qw(dclone);
    use Data::Structure::Util qw(unbless);

    my $unblessed_clone = unbless( dclone($self) );
    return $unblessed_clone;
}
