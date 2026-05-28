#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin qw/$Bin/;
use Parse::Crontab;

use lib '../lib';

use Parse::Crontab::English;

my $test_file = "$Bin/crontab.test";

{
    my $data = Parse::Crontab::English->new ( { file => $test_file } );
    ok ( defined $data, "Test file $test_file loaded" );

    is ( ref $data->{ base }{ entries }, 'ARRAY', "Expected an AoA data type" );

    done_testing;
}
