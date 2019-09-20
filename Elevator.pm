package Elevator;

use strict;
use warnings;
use feature qw/ say /;

use constant FALSE => 0;
use constant TRUE => 1;

use Moose;
use List::Util qw/ any /;

use Call;

has 'id'         => (is => 'rw', isa => 'Int');
has 'floor'      => (is => 'rw', isa => 'Int');
has 'passengers' => (is => 'rw', isa => 'ArrayRef[Call]');
has 'status'     => (is => 'rw', isa => 'Str');

sub towards {
    my $self = shift;
    return 'UP' if $self->passengers->[0]->end > $self->floor;
    return 'DOWN';
}

sub is_empty {
    my $self = shift;
    return TRUE if @{$self->passengers} == 0;
    return FALSE;
}

sub grep_end_floor_passengers {
    my $self = shift;
    my $floor = $self->floor;
    my @passengers = grep { $_->end == $floor }
                     @{$self->passengers};
    return \@passengers;
}

sub any_end_passenger {
    my $self = shift;
    return TRUE 
        if any { 
            $_->end == $self->floor 
        } @{$self->passengers};
    return FALSE;
}

sub is_full {
    my $self = shift;
    return TRUE if @{$self->passengers} == 8;
    return FALSE;
}

sub TO_JSON {
    my( $self ) = shift;

    %$self = %$self{qw/ id floor passengers status /};

    use Storable qw(dclone);

    # https://metacpan.org/pod/Data::Structure::Util
    use Data::Structure::Util qw(unbless);

    my $unblessed_clone = unbless( dclone($self) );
    return $unblessed_clone;
}

1;
