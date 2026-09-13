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
    is ( 45, scalar keys %{ $obj->{ summary } }, "Check key count in summary" );

    #  Let's check back with the original on a few things.

    TODO: {

      local $TODO = "Under development";
      foreach my $cmd ( keys %{ $obj->{ summary } } ) {

        my $loaded = $obj->{ summary }{ $cmd };
        ok ( defined $loaded, "Load summary" );
        cmp_ok ( $loaded->{ line_num }, '<', 45, "Check line count" );

        my $orig_line = $obj->{ base }{ entries }[ $loaded->{ line_num } ];
        ok ( defined $orig_line, "Original line exists" );
      }
    }

    done_testing;
}
