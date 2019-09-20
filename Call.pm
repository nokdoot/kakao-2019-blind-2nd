package Call;

use strict;
use warnings;

use constant TRUE => 1;
use constant FALSE => 0;

use Moose;

has 'id'        => (is => 'ro', isa => 'Int');
has 'timestamp' => (is => 'ro', isa => 'Int');
has 'start'     => (is => 'ro', isa => 'Int');
has 'end'       => (is => 'ro', isa => 'Int');

sub towards {
    my $self = shift;
    return 'UP' if $self->start < $self->end;
    return 'DOWN';
}

1;
