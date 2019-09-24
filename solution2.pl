#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;
use Data::Dumper;
use constant FALSE => 0;
use constant TRUE => 1;

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
my $problem_id = 2;
my $number_of_elevators = 4;
my $user_key = 'nokdoot';

my $start = API->start_api({
    server_url          => $server_url,
    problem_id          => $problem_id,
    number_of_elevators => $number_of_elevators,
    user_key            => $user_key,
});

my $token = $start->{token};
my $elevators = [];
$elevators = new_elevators($elevators, $start->{elevators});
my $timestamp = $start->{timestamp};
my @call_occupied_by = ();

while ( TRUE ) {
    my $on_calls = API->on_calls_api({
        server_url  => $server_url,
        token       => $token,
    });
    
    last if $on_calls->{is_end}; 

    my $commands = [];

    my $all_calls 
        = [ map { Call->new($_) } @{ $on_calls->{calls} } ];

    $elevators = new_elevators($elevators, $on_calls->{elevators});

    ELEVATOR:
    for my $elevator ( @$elevators ) {
        my $commmand;
        my $floor = $elevator->floor;
        my $status = $elevator->status;
        my $id = $elevator->id;

        if ( defined $call_occupied_by[$id] ) {
            my $call = $call_occupied_by[$id];
            if ( $floor == $call->start ) {
                my $command = make_command($elevator, 'STOP');
                push @$commands, $command;
                $call_occupied_by[$id] = undef;
                next ELEVATOR;
            }
            else {
                my $command 
                    = command_move_to_call($elevator, $call);
                push @$commands, $command;
                next ELEVATOR;
            }
        }

        if ( $status eq 'STOPPED' ) {
            if ( $elevator->any_end_passenger ){
                my $command = make_command($elevator, 'OPEN');
                push @$commands, $command;
                next ELEVATOR;
            }
            
            if ( 
                any_start_call($elevator, $all_calls)
                and (
                    $elevator->is_empty
                    or (
                        !$elevator->is_full 
                    )
                )
            ) {
                my $command = make_command($elevator, 'OPEN');
                push @$commands, $command;
                next ELEVATOR;
            }

            if ( $elevator->is_empty ) {
                CALL:
                for my $call ( @$all_calls ) {
                    for ( @call_occupied_by ) {
                        next if !defined $_;
                        next CALL if $_->start == $call->start;
                    }
                    $call_occupied_by[$id] = $call;
                    my $command 
                        = command_move_to_call($elevator, $call);
                    push @$commands, $command;
                    next ELEVATOR;
                }
                my $command = make_command($elevator, 'STOP');
                push @$commands, $command;
                next ELEVATOR;
            }
            else {
                my $command 
                    = make_command($elevator, $elevator->towards);
                push @$commands, $command;
                next ELEVATOR;
            }
        }
        elsif ( $elevator->status eq 'OPENED' ) {
            if ( $elevator->any_end_passenger ){
                my $command = command_exit($elevator);
                push @$commands, $command;
                next ELEVATOR;
            }

            if (
                any_start_call($elevator, $all_calls)
                and (
                    $elevator->is_empty
                    or (
                        !$elevator->is_full
                    )
                )
            ) {
                my $command 
                    = command_enter($elevator, $all_calls);
                push @$commands, $command;
                next ELEVATOR;
            }

            my $command = make_command($elevator, 'CLOSE');
            push @$commands, $command;
            next ELEVATOR;
        }
        elsif ( $elevator->status eq 'UPWARD'
                || $elevator->status eq 'DOWNWARD' ) {
            if ( $elevator->any_end_passenger ) {
                my $command = make_command($elevator, 'STOP');
                push @$commands, $command;
                next ELEVATOR;
            }

            if (
                any_start_call($elevator, $all_calls)
                and (
                    $elevator->is_empty
                    or (
                        !$elevator->is_full
                        and any_same_toward($elevator, $all_calls)
                    )
                )
            ) {
                my $command = make_command($elevator, 'STOP');
                push @$commands, $command;
                next ELEVATOR;
            }

            if ( $elevator->status eq 'UPWARD' ) {
                my $command = make_command($elevator, 'UP');
                push @$commands, $command;
                next ELEVATOR;
            }
            else {
                my $command = make_command($elevator, 'DOWN');
                push @$commands, $command;
                next ELEVATOR;
            }
        }
    }

    my $action = API->action_api({
        server_url  => $server_url,
        token       => $token,
        commands    => $commands,
    });

    $timestamp = $action->{timestamp};
    say $timestamp;
    sleep(0.025);
}

sub command_move_to_call {
    my ($elevator, $call) = @_;
    my $command = "";

    if ( $elevator->floor > $call->start ) {
        $command = 'DOWN';
    }
    else {
        $command = 'UP';
    }
    return Command->new({
        elevator_id => $elevator->id,
        command     => $command,
    });
}

sub grep_enter_calls {
    my ($elevator, $all_calls) = @_;
    my $passengers = $elevator->passengers;

    my $calls = [];

    for my $call ( @$all_calls ) {
        last if @$passengers == 8;
        next if $call->start != $elevator->floor;

        if ( not @$passengers ) {
            push @$passengers, $call;
            push @$calls, $call;
            next;
        }

        my $passenger = $passengers->[0];
        if ( $call->towards eq $elevator->towards ) {
            push @$passengers, $call;
            push @$calls, $call;
            next;
        }
    }

    return $calls;
}

sub command_enter {
    my ($elevator, $all_calls) = @_;

    my $calls = grep_enter_calls($elevator, $all_calls);

    @{$all_calls} = @{ difference_of_calls($all_calls, $calls) };

    my @call_ids = map { int($_->id) } @$calls;

    return Command->new({
        elevator_id => $elevator->id,
        command     => 'ENTER',
        call_ids    => \@call_ids
    });
}

sub difference_of_calls {
    my ($a, $b) = @_;
    my $diff = [];
    my %count = ();
    for ( 
        (map { $_->id } @$a), 
        (map { $_->id } @$b) 
    ) {
        $count{$_}++;
    }
    for ( @$a ) {
        push @$diff, $_ if $count{$_->id} == 1;
    }
    return $diff;
}

sub command_exit {
    my $elevator = shift;
    my $floor = $elevator->floor;
    my $passengers = $elevator->passengers;
    my @call_ids = map  { $_->id } 
                   grep { $_->end == $floor } @$passengers;

    @$passengers = grep { $_->end != $floor } @$passengers;

    Command->new({
        elevator_id => $elevator->id,
        command     => 'EXIT',
        call_ids    => \@call_ids,
    });
}

sub make_command {
    my ($elevator, $cmd) = @_;
    my $command = Command->new({
        elevator_id => $elevator->id,
        command     => $cmd,
    });

    return $command;
}

sub any_same_toward {
    my ($elevator, $all_calls) = @_;
    return TRUE
        if !@{ $elevator->passengers } 
        or any {
            $_->towards eq $elevator->towards
        } @$all_calls;
    return FALSE;
}

sub any_start_call {
    my ($elevator, $all_calls) = @_;
    return TRUE 
        if any { 
            $_->start == $elevator->floor 
            and ($elevator->is_empty 
            or $_->towards eq $elevator->towards)
        } @$all_calls;
    return FALSE;
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
            my @passengers
                = map { Call->new($_) }
                  @{ $json_of_elev->{passengers} };
            my %elevator = %$json_of_elev{qw/ id floor status/};
            $elevator{passengers} = \@passengers;
            bless \%elevator, 'Elevator';
            $new_elevators->[$id] = \%elevator;
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
