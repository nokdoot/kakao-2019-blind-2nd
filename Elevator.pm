package Elevator;

use strict;
use warnings;

use Moose;

use Call;

has 'id' => (is => 'ro', isa => 'Int');
has 'floor' => (is => 'ro', isa => 'Int');
has 'passengers' => (is => 'rw', isa => 'ArrayRef[Call]');
has 'status' => (is => 'ro', isa => 'Str');

1;
