package Parse::Crontab::English;

use 5.006;
use strict;
use warnings;

use List::Util qw/uniq/;

=head1 NAME

Parse::Crontab::English - Generate useful English documentation on how often a command runs.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Parses the supplied crontab (using Parse::Crontab) and then examines the data
in order to create an explanation of how often a command runs.

Perhaps a little code snippet.

    use Parse::Crontab::English;

    my $foo = Parse::Crontab::English->new( file => 'crontab.lst');
    ...

=head1 SUBROUTINES/METHODS

TO COME

=cut

sub new
{
    my ( $class, $args ) = @_;

    my $base = Parse::Crontab->new ( file => $args->{ file } );
    defined $base or return undef;

    my $self = { base => $base };

    bless ( $self, $class );

    $self->load;
    return $self;
}

sub load
{
    my ( $self ) = @_;

    my %data;
    my $line_num = 0;   #  Line number from original entry.

    foreach my $line ( @{ $self->{ base }{ entries } } ) {

      push ( @{ $data{ $line->{ command } } },
        { day_range  => $line->{ schedule }{ day }{ expanded },
          dow_range  => $line->{ schedule }{ day_of_week }{ expanded },
          hour_range => $line->{ schedule }{ hour }{ expanded },
          min_range  => $line->{ schedule }{ minute }{ expanded },
          mon_range  => $line->{ schedule }{ month }{ expanded } } );

      #  Get the entry so we have less typing to do. Then, if we see the range
      #  of days is min to max, add 'all days' to the english description. More
      #  to come, obviously.

      my $entry = $data{ $line->{ command } }[ -1 ];

      #  Well, it looks like the parent module sometimes messes up and reads 7
      #  (Sunday) as both 0 and 7 -- meaning that we get two entries, both of
      #  them Sunday. So now I'm going to do some de-duplication on that mess.
      #  One side effect is that I won't have to pop off the last element of
      #  the array, since we'll now have a maximum of seven items.

      $entry->{ dow_range } =
        [ uniq ( map { $_ % 7  } @{ $entry->{ dow_range } } ) ];

      if ( @{ $entry->{ day_range } } == 31 ) {

        $entry->{ days_english } = 'every day of the month';

      } else {

        $entry->{ days_english } =
          "The following " . scalar @{ $entry->{ day_range } } .
          " days: " . join ( ', ', @{ $entry->{ day_range } } );

        if ( $entry->{ days_english } =~ /, / ) {

          $entry->{ days_english } =~ s/(.+), /$1, and /;
        }
      }

      #  Check Day of Week .. If the range is 0 .. 6, it's every day.

      my %days = (
        0 => 'Sunday',   1 => 'Monday', 2 => 'Tuesday',  3 => 'Wednesday',
        4 => 'Thursday', 5 => 'Friday', 6 => 'Saturday', 7 => 'Sunday',
      );

      if ( @{ $entry->{ dow_range } } == 7 ) {

        $entry->{ dow_number } = 'every day of the week';
        $entry->{ dow_name }   = 'every day of the week';

      } elsif ( @{ $entry->{ dow_range } } == 1 ) {

        $entry->{ dow_number } = 'just on day ' .    $entry->{ dow_range }[ 0 ];
        $entry->{ dow_name }   = 'just on ' . $days{ $entry->{ dow_range }[ 0 ] };

      } else {

        $entry->{ dow_number } = 
          "The following " . scalar @{ $entry->{ dow_range } } .
          " days of the week: " . join ( ', ', @{ $entry->{ dow_range } } );

        if ( $entry->{ dow_number } =~ /, / ) {

          $entry->{ dow_number } =~ s/(.+), /$1, and /;
        }

        $entry->{ dow_name } = 
          "The following " . scalar @{ $entry->{ dow_range } } .
          " days of the week: " . join ( ', ', map { $days{ $_ } } @{ $entry->{ dow_range } } );

        if ( $entry->{ dow_name } =~ /, / ) {

          $entry->{ dow_name } =~ s/(.+), /$1, and /;
        }

        #  For my next trick, I'm going to see if I can reduce the list to a
        #  range, in order to map 1-5 to Monday to Friday. All we know about
        #  the list of day numbers is that they're ordered.

        my ( $first_day, $last_day, @ranges );

        foreach my $off ( 0 .. 6 ) {

          my $this_day = $entry->{ dow_range }[ $off ];
          if ( !defined $this_day ) { next; }

          if ( defined $first_day ) {

            if ( defined $last_day ) {

              if ( $last_day + 1 == $this_day ) {

                #  We're still in order, continue.

                $last_day = $this_day;

              } else {

                #  Not in order -- need to close off previous order and start a new one.

                push ( @ranges, [ $first_day, $last_day ] );

                $first_day = $this_day;
                undef $last_day;
              }
              
            } else {

              if ( $first_day + 1 == $this_day ) {

                #  We're still in order, continue.

                $last_day = $entry->{ dow_range }[ $off ];

              } else {

                #  Not in order -- need to close off previous order and start a new one.

                push ( @ranges, [ $first_day, $first_day ] );
                $first_day = $entry->{ dow_range }[ $off ];
              }
            }

          } else {

            $first_day = $entry->{ dow_range }[ $off ];
          }
        }

        #  We may need to capture the last range ..

        if ( @ranges == 0 || defined $first_day ) {

          if ( defined $last_day ) {

            push ( @ranges, [ $first_day, $last_day ] );

          } else {

            push ( @ranges, [ $first_day, $first_day ] );
          }
        }

        #  Create name_short using the ranges we've found.

        my @day_list;
        foreach my $r ( @ranges ) {

          if ( $r->[ 0 ] == $r->[ 1 ] ) {

            push ( @day_list, $days{ $r->[ 0 ] } );

          } else {

            push ( @day_list, "$days{ $r->[ 0 ] } to $days{ $r->[ 1 ] }" );
          }

          $entry->{ dow_name_range } = join ( ', ', @day_list );
          if ( $entry->{ dow_name_range } =~ /, / ) {

            $entry->{ dow_name_range } =~ s/(.+), /$1, and /;
          }
        }
      }

      #  Now I'd like to show all of the possible times. This may be a lot.

      #  If it's every minute, then just show that, plus the hours.

      my $hours = join ( ', ', map { "${_}h00" } @{ $entry->{ hour_range } } );
      if ( $hours =~ /, / ) { $hours =~ s/(.+), /$1, and /; }

      if ( @{ $entry->{ min_range } } == 60 ) {

        $entry->{ hours_minutes } = "every minute of the following hours: $hours";

        #  Later, we can convert the 24 hour values to am/pm if necessary. Or I
        #  might have a function that takes the hour and minute and returns an
        #  appropriately formatted time. (There's a bit of copy-pasta going on
        #  here, obviously.)

        $entry->{ hm_short } = "every minute, for " .
          ( scalar @{ $entry->{ hour_range } } ) . " hours, from " .
          hm ( @{ $entry->{ hour_range } }[  0 ] ) . " to " .
          hm ( @{ $entry->{ hour_range } }[ -1 ] );

      } else {

        #  We're going to show the hours and minutes in a list. The shorter
        #  version of the list follows.

        my $minutes =
          join ( ', ', map { sprintf ( ":%02d", $_ ) } @{ $entry->{ min_range } } );
        if ( $minutes =~ /, / ) { $minutes =~ s/(.+), /$1, and /; }

        #  Clean up the output a little.

        $entry->{ hours_minutes } =
          ( @{ $entry->{ hour_range } } > 1 ? "at the hours" : "at" ) .
          " $hours, at $minutes after the hour";

        #  Prepare the short description. The description for the one-time cron
        #  job is much shorter.

        my $times = scalar @{ $entry->{ hour_range } } *
                    scalar @{ $entry->{ min_range } };

        if ( $times == 1 ) {

          $entry->{ hm_short } = "Once, at " .
            hm ( $entry->{ hour_range }->[ 0 ], $entry->{ min_range }->[ 0 ] );

        } else {

          $entry->{ hm_short } = "$times times, starting at " .
            hm ( @{ $entry->{ hour_range } }[  0 ], @{ $entry->{ min_range } }[   0 ] ) .
            ", and ending at " . 
            hm ( @{ $entry->{ hour_range } }[ -1 ], @{ $entry->{ min_range } }[  -1 ] );
        }
      }

      #  Add line number ..

      $entry->{ line_num } = $line_num++;
    }
    $self->{ summary } = \%data;
}

#  Format the time into a common format. This will replace a lot of copy pasta
#  from earlier versions. If called with just an hour, we assume zero minutes.

sub hm
{
    my ( $h, $m ) = @_;

    return ( sprintf ( "${h}h%02d", $m // 0 ) );
}


=head1 AUTHOR

T. Alex Beamish, C<< <talexb at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-crontab-english at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-Crontab-English>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::Crontab::English


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Crontab-English>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Parse-Crontab-English>

=item * Search CPAN

L<https://metacpan.org/release/Parse-Crontab-English>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by T. Alex Beamish.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Parse::Crontab::English
