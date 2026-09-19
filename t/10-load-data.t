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

          if ( $e->{ day_range }[ 0 ] == 1 && $e->{ day_range }[ -1 ] == 31 ) {

            is ( $e->{ days_english },
              'every day of the month', "Full day range -> every day (month)" );

          } else {

            like ( $e->{ days_english }, qr/The following \d+ days:/,
              "Reasonable list of days of the week." );
            diag ( "Day range is @{ $e->{ day_range } }" );
          }

          #  Check for all days of the week ..

          if ( ( $e->{ dow_range }[  0 ] == 0 &&
                 $e->{ dow_range }[ -1 ] == 6 ) ||
               ( $e->{ dow_range }[  0 ] == 1 &&
                 $e->{ dow_range }[ -1 ] == 7 ) ) {

            is ( $e->{ dow_english },
              'every day of the week', "Full day range -> every day (week)" );

          } elsif ( @{ $e->{ dow_range } } == 1 ) {

            like ( $e->{ dow_english },
              qr/just on day \d/, "Single day of the week" );

          } else {

            like ( $e->{ dow_english }, qr/The following \d+ days of the week:/,
              "Reasonable list of days of the week." );
            diag ( "Week day range is @{ $e->{ dow_range } }" );
          }
          diag ( "DOW: $e->{ dow_english }" );

          #  Check that something's there for the hours_minutes ..

          ok ( defined $e->{ hours_minutes }, "Hours and minutes defined" );
          diag ( "H+M: $e->{ hours_minutes }" );

          #  .. and if it's less than every hour, that each hour is present; and

          if ( @{ $e->{ hour_range } } < 24 ) {

            foreach my $h ( @{ $e->{ hour_range } } ) {

              like ( $e->{ hours_minutes }, qr/${h}h00/, "Saw entry for hour $h" );
            }
          }

          #  .. and if it's less than every minute, check for those values too.

          if ( @{ $e->{ min_range } } < 60 ) {

            foreach my $m ( @{ $e->{ min_range } } ) {

              like ( $e->{ hours_minutes }, qr/:$m/, "Saw entry for minute $m" );
            }
          }

          #  Check that something's there for the hr_short ..

          ok ( defined $e->{ hm_short }, "Hours and minutes short defined" );
          diag ( "HM: $e->{ hm_short }" );

          #  Check for original line ..

          my $orig_line = $obj->{ base }{ entries }[ $e->{ line_num } ];
          ok ( defined $orig_line, "Original line exists" );
        }
      }
    }

    done_testing;
}
