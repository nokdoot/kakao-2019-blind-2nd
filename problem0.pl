#!/usr/bin/env perl

use warnings;
use feature qw/ say /;
use Data::Dumper;
use constant FALSE => 0;
use constant TRUE => 1;
use constant TOWARDS_CALL => 2;

use FindBin;
use lib "$FindBin::Bin/local/lib/perl5";
use lib './';
use JSON::XS;
use List::Util qw / any /;
use Carp;
use Time::HiRes qw / sleep /;

use API;
use Elevator;
use Call;
use Command;

my $server_url = 'http://localhost:8000';
my $problem_id = 0;
my $number_of_elevators = 4;
my $user_key = 'nokdoot';

my $start = API->start_api({
    server_url          => $server_url,
    problem_id          => $problem_id,
    number_of_elevators => $number_of_elevators,
    user_key            => $user_key,
});

my $token = $start->{token};
my $elevators;
$elevators = new_elevators($elevators, $start->{elevators});
my $timestamp = $start->{timestamp};

while ( TRUE ) {
    print "$timestamp ";
    my $on_calls = API->on_calls_api({
        server_url  => $server_url,
        token       => $token,
    });
    
    #say Dumper $on_calls;

    last if $on_calls->{is_end} == TRUE;

    my $commands = [];

    my @all_calls = map { Call->new($_) } @{ $on_calls->{calls} };

    $elevators = new_elevators($elevators, $on_calls->{elevators});

    ELEVATOR:
    for my $elevator ( @$elevators ) {
        my $commmand;
        my $floor = $elevator->floor;
        my $going_to = $elevator->going_to;

        if ( $going_to != 0 ) {
            if ( $going_to == $floor ) {
                my $command = make_command($elevator, 'STOP');
                push @$commands, $command;
                $elevator->going_to(0);
                next;
            }
            my $command 
                = make_command($elevator, 'MOVE', $going_to);
            push @$commands, $command;
            next;
        }

        if ( $elevator->status eq 'STOPPED' ) {
            my $passengers = $elevator->grep_end_floor_passengers;
            if ( @$passengers ) {
                $command = make_command($elevator, 'OPEN');
                push @$commands, $command;
                next;
            }

            my @calls = grep {
                $_->start == $floor 
            } @all_calls;

            if ( @calls ) {
                $command = make_command($elevator, 'OPEN');
                push @$commands, $command;
                next;
            }

            if ( $elevator->is_empty ) {
                CALLS:
                for my $call ( @all_calls ) {
                    $dest = $call->start;
                    for ( @$elevators ) {
                        if ( $_->going_to == $dest ) {
                            next CALLS;
                        }
                    }
                    $elevator->going_to($dest);
                    my $command 
                        = make_command($elevator, 'MOVE', $dest);
                    push @$commands, $command;
                    next ELEVATOR;
                }
                my $command = make_command($elevator, 'STOP');
                push @$commands, $command;
            }
            else {
                my $command 
                    = make_command($elevator, $elevator->towards);
                push @$commands, $command;
            }
        }
        elsif ( $elevator->status eq 'OPENED' ) {
            my $passengers = $elevator->grep_end_floor_passengers;
            if ( @$passengers ) {
                my $command = command_exit($elevator, \@all_calls);
                push @$commands, $command;
                next;
            }

            if ( any { $_->start == $floor } @all_calls ) {
                my $command = command_enter($elevator, \@all_calls);
                push @$commands, $command;
                next;
            }
            my $command = make_command($elevator, 'CLOSE');
            push @$commands, $command;
        }
        elsif ( $elevator->status eq 'UPWARD'
                || $elevator->status eq 'DOWNWARD' ) {
            my $passengers = $elevator->grep_end_floor_passengers;
            if ( @$passengers ) {
                my $command = make_command($elevator, 'STOP');
                push @$commands, $command;
                next;
            }

            my @calls = grep { $_->start == $floor } @all_calls;
            if ( @calls ) {
                my $command = make_command($elevator, 'STOP');
                push @$commands, $command;
                next;
            }

            if ( $elevator->status eq 'UPWARD' ) {
                my $command = make_command($elevator, 'UP');
                push @$commands, $command;
            }
            else {
                my $command = make_command($elevator, 'DOWN');
                push @$commands, $command;
            }
        }
    }

    say Dumper "on_calls", $on_calls;
    say Dumper ("elevators", $elevators);
    say Dumper ("commands", $commands);
    say "=======";

    my $action = API->action_api({
        server_url  => $server_url,
        token       => $token,
        commands    => $commands,
    });

    #say Dumper $action;

    $timestamp = $action->{timestamp};
    sleep(0.025);
}

# say $timestamp;

sub command_enter {
    my ($elevator, $all_calls) = @_;
    my $passengers = $elevator->passengers;
    my $size = scalar @$passengers;

    my @call_ids 
        = map  { $_->id }
          grep { $_->start == $elevator->floor } @$all_calls;
    @call_ids = splice (@call_ids, 0, 8-$size);
    push @{ $elevator->passengers }, @call_ids;

    @$all_calls 
        = grep { $_->start != $elevator->floor } @$all_calls;

    return Command->new({
        elevator_id => $elevator->id,
        command     => 'ENTER',
        call_ids    => \@call_ids,
    });
}

sub command_exit {
    my ($elevator) = @_;
    my $floor = $elevator->floor;
    my @call_ids 
        = map  { $_->id } 
          grep { $_->end == $floor } @{ $elevator->passengers };
    @{ $elevator->passengers }
        = grep { $_->end != $floor } @{ $elevator->passengers };
    Command->new({
        elevator_id => $elevator->id,
        command     => 'EXIT',
        call_ids    => \@call_ids,
    });
}

sub make_command {
    my ($elevator, $cmd, $dest) = @_;
    if ( $cmd eq 'MOVE' ) {
        if ( $dest > $elevator->floor ) {
            $cmd = 'UP';
        }
        else {
            $cmd = 'DOWN';
        }
    }
    my $command = Command->new({
        elevator_id => $elevator->id,
        command     => $cmd,
    });

    return $command;
}

sub new_elevators {
    my $elevators = shift;
    my $json_of_eleves = shift;

    my $new_elevators = [];

    if ( !defined $elevators ) {
        for my $json_of_elev ( @$json_of_eleves ) {
            my $new_elevator = Elevator->new($json_of_elev);
            my $id = $new_elevator->{id};
            $new_elevators->[$id] = $new_elevator;
        }
    }
    else {
        for my $json_of_elev ( @$json_of_eleves ) {
            my $id = $json_of_elev->{id};
            my $elevator = $elevators->[$id];
            my @passengers
                = map { Call->new($_) }
                  @{ $json_of_elev->{passengers} };
            #say Dumper $json_of_elev->{passengers};
            $elevator->id($json_of_elev->{id});
            $elevator->floor($json_of_elev->{floor});
            $elevator->passengers(\@passengers);
            $elevator->status($json_of_elev->{status});
            $new_elevators->[$id] = $elevator;
        }
    }

    return $new_elevators;
}

=pod 

https://stackoverflow.com/questions/2329385/how-can-i-unbless-an-object-in-perl/4783486
written by brian d foy

=cut

sub UNIVERSAL::TO_JSON {
    my( $self ) = shift;

    use Storable qw(dclone);

    # https://metacpan.org/pod/Data::Structure::Util
    use Data::Structure::Util qw(unbless);

    my $unblessed_clone = unbless( dclone($self) );
    return $unblessed_clone;
}
