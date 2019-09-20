package API;

use strict;
use warnings;
use feature qw/ say /;
use constant TRUE => 1;
use constant FALSE => 0;
use Carp;
use Data::Dumper;

# https://metacpan.org/pod/REST::Client
use REST::Client;
#use Mojo::JSON qw/ encode_json decode_json /;
use JSON::XS;
#use Cpanel::JSON::XS;

sub start_api {
    my $class = shift;
    my $args = shift;
    my $server_url = $args->{server_url};
    my $problem_id = $args->{problem_id};
    my $number_of_elevators = $args->{number_of_elevators};
    my $user_key = $args->{user_key};
    my $client = REST::Client->new();
    $client->setHost($server_url);
    $client->POST(
        "/start/$user_key/$problem_id/$number_of_elevators");
    
    return undef if check_http_status($client) == FALSE;

    my $responseContent = $client->responseContent;
    return decode_json($responseContent);
}

sub on_calls_api {
    my $class = shift;
    my $args = shift;
    my $server_url = $args->{server_url};
    my $token = $args->{token};
    my $client = REST::Client->new();
    $client->setHost($server_url);
    $client->addHeader('X-Auth-Token', $token);
    $client->GET("/oncalls");

    return undef if check_http_status($client) == FALSE;

    my $responseContent = $client->responseContent;
#     say Dumper $responseContent;
    return decode_json($responseContent);
}

sub action_api {
    my $class = shift;
    my $args = shift;
    my $server_url = $args->{server_url};
    my $token = $args->{token};

    my $json_converter = JSON::XS->new->convert_blessed(1);
    my $commands = $json_converter->encode( $args->{commands} );

    my $client = REST::Client->new();
    $client->setHost($server_url);
    $client->addHeader('X-Auth-Token', $token);
    $client->addHeader('Content-Type', 'application/json');
    $client->POST(
        "/action", 
        qq/{
            "commands" : $commands
        }/
    );

    return undef if check_http_status($client) == FALSE;

    my $responseContent = $client->responseContent;
    return decode_json($responseContent);
}

sub check_http_status {
    my $client = shift;
    if( $client->responseCode() eq '400' ){
        croak "형식 또는 범위가 잘못됨";
        return FALSE;
    }
    elsif( $client->responseCode() eq '401' ){
        croak "X-Auth-Token Header가 잘못됨";
        return FALSE;
    }
    elsif( $client->responseCode() eq '403' ){
        croak "user_key가 잘못되었거나 10초 이내에 생성한 토큰이 존재";
        return FALSE;
    }
    elsif( $client->responseCode() eq '500' ){
        croak "서버 에러, 문의 필요";
        return FALSE;
    }

    if( $client->responseCode() ne '200' ){
        croak "알 수 없는 responseCode";
        return FALSE;
    }
    return TRUE;
}

1;
