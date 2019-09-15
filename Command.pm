package Command;

use strict;
use warnings;
use feature qw/ say /;
use Data::Dumper;

use Moose;

has 'elevator_id' => ( is => 'ro', isa => 'Int' );
has 'command'     => ( is => 'ro', isa => 'Str' );
has 'call_ids'    => ( is => 'ro', isa => 'ArrayRef[Int]');

1;
