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

    TODO:
    {
      local $TODO = 'Under developer';

      foreach my $ent ( keys %{ $obj->{ summary } } ) {

        foreach my $e ( @{ $obj->{ summary }{ $ent } } ) {

          #  Check for all days ..

          if ( $e->{ day_range }[ 0 ] == 1 &&
               $e->{ day_range }[ 1 ] == 31 ) {

            is ( $e->{ days_english }, 'all days', "Full day range -> all days" );
          }

          #  Check for original line ..

          my $orig_line = $obj->{ base }{ entries }[ $e->{ line_num } ];
          ok ( defined $orig_line, "Original line exists" );
        }
      }
    }

    done_testing;
}
