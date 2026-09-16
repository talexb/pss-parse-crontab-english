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

          #  Check for all days of the month ..

          is ( $e->{ days_english },
            'every day of the month', "Full day range -> every day (month)" );

          #  Check for all days of the week ..

          if ( $e->{ day_range }[ 0 ] == 0 &&
               $e->{ day_range }[ 1 ] == 6 ) {

            is ( $e->{ dow_english },
              'every day of the week', "Full day range -> every day (week)" );
          }

          #  Check for original line ..

          my $orig_line = $obj->{ base }{ entries }[ $e->{ line_num } ];
          ok ( defined $orig_line, "Original line exists" );
        }
      }
    }

    done_testing;
}
