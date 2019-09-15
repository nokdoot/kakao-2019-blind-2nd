#!/usr/bin/env perl

use warnings;
use feature qw/ say /;
use Data::Dumper;
use constant TRUE => 1;
use constant FALSE => 0;

use FindBin;
use lib "$FindBin::Bin/local/lib/perl5";
use lib './';
use JSON::XS;

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
my $elevator = get_elevators_from($start->{elevators});
my $timestamp = $start->{timestamp};
my @dest_of = (0)x4;

#while ( TRUE ) {
    print "$timestamp ";
    my $on_calls = API->on_calls_api({
        server_url  => $server_url,
        token       => $token,
    });

    last if $on_calls->{is_end} == TRUE;

    my $floor = [];
    my @calls = map { Call->new($_) } @{ $on_calls->{calls} };
    for my $call ( @calls ) {
        my $start = $call->start;
        push @{$floor->[$start]}, $call;
    }

    my @elevators = sort { $a->id <=> $b->id } 
                    map  { Elevator->new($_) }
                    @{ $on_calls->{elevators} };

    my $commands = [];

    push @$commands, Command->new({
        elevator_id => 0,
        command     => 'UP',
    });
    push @$commands, Command->new({
        elevator_id => 1,
        command     => 'UP',
    });
    push @$commands, Command->new({
        elevator_id => 2,
        command     => 'UP',
    });
    push @$commands, Command->new({
        elevator_id => 3,
        command     => 'UP',
    });

    my $action = API->action_api({
        server_url  => $server_url,
        token       => $token,
        commands    => $commands,
    });
    $action = API->action_api({
        server_url  => $server_url,
        token       => $token,
        commands    => $commands,
    });

    $timestamp = $action->{timestamp};

#}

say "";

say $timestamp;

sub get_elevators_from {
    my $json_of_elevators = shift;
    my @elevators = ();
    for my $json_of_elevator ( @$json_of_elevators ) {
        my $new_elevator = Elevator->new($json_of_elevator);
        push @elevators, $new_elevator;
    }
    return \@elevators;
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
