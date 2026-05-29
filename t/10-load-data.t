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
    my $obj = Parse::Crontab::English->new ( { file => $test_file } );
    ok ( defined $obj, "Test file $test_file loaded" );

    is ( ref $obj->{ base }{ entries }, 'ARRAY', "Expected an AoA data type" );
    ok ( exists ( $obj->{ summary } ), "Summary exists" );

    done_testing;
}
