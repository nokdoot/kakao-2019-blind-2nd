#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../local/lib/perl5";

use REST::Client;
use Test::Simple;
use JSON::XS;


my $server_url = 'http://localhost:8000';
my $client = REST::Client->new();
$client->setHost($server_url);
$client->POST('/start/nokdoot/0/1');

if( $client->responseCode() eq '400' ){
    say "problem_id 또는 number_of_elevators의 "
        ."형식 또는 범위가 잘못됨";
    exit(1);
}
elsif( $client->responseCode() eq '401' ){
    say "X-Auth-Token Header가 잘못됨";
    exit(1);
}
elsif( $client->responseCode() eq '403' ){
    say "user_key가 잘못되었거나 10초 이내에 생성한 토큰이 존재";
    exit(1);
}
elsif( $client->responseCode() eq '500' ){
    say "서버 에러, 문의 필요";
    exit(1);
}

if( $client->responseCode() ne '200' ){
    say "알 수 없는 responseCode";
    exit(1);
}

my $response = $client->responseContent;
my $res = decode_json $response;
say $res->{token};
say Dumper $res;
say $response;
