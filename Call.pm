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

sub towards_up {
    my $self = shift;
    return TRUE if $self->end > $self->start;
    return FALSE;
}

sub towards_down {
    my $self = shift;
    return FALSE if $self->towards_up;
    return TRUE;
}

1;
