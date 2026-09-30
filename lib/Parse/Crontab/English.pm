package Parse::Crontab::English;

use 5.006;
use strict;
use warnings;

use Parse::Crontab;
use List::Util qw/uniq/;

=head1 NAME

Parse::Crontab::English - Generate useful English documentation on how often a command runs.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Parses the supplied crontab (using Parse::Crontab) and then examines the data
in order to create a comprehensive explanation of how often a command runs.

Perhaps a little code snippet.

    use Parse::Crontab::English;

    my $foo = Parse::Crontab::English->new( file => 'crontab.lst');

We now have the full details of each relevant crontab line in $foo->{ base },
and a summary in $foo->{ summary } as a HoA (hash of arrays).  The hash key is
the command line (the last entry in the line from crontab), and the detail
consists of days of the month, days of the week, a complete list of the times
(hours and minutes) of each run, and a summary of the same times.

Because a command may have multiple entries (perhaps a weekday run and a
different weekend run), this is an array.

So, for the crontab line

    15  9-17 *   *   0-2,4,6 cd /home/xyz/extra && ./several_days.sh >sev.out 2>sev.err

the detail for 'cd /home/xyz/extra && ./several_days.sh >sev.out 2>sev.er'
will contain

    'months_english' => 'every month'
    'days_english' => 'every day of the month'
    'dow_name' => 'the following 5 days of the week: Sunday, Monday, Tuesday, Thursday, and Saturday'
    'dow_name_range' => 'Sunday to Tuesday, Thursday, and Saturday'
    'dow_number' => 'the following 5 days of the week: 0, 1, 2, 4, and 6'
    'hours_minutes' => 'at the hours 9h00, 10h00, 11h00, 12h00, 13h00, 14h00, 15h00, 16h00, and 17h00, at :15 after the hour'
    'hm_short' => '9 times daily (once an hour), starting at 9h15, and ending at 17h15'

There is a variety of long and short descriptions for the months, days of the
month, days of the week, hours, and minutes.

The example script 'explain_crontab' shows the following result for this line:

    Command line: cd /home/xyz/extra && ./several_days.sh >sev.out 2>sev.err
    --> Detail (line 1):
      --> Days of the week: Sunday to Tuesday, Thursday, and Saturday
      --> Hours and Minutes: 9 times daily (once an hour), starting at 9h15, and ending at 17h15

Since both 'every day of the month' and 'every month' are the defaults, the
script cuts those comments out of the summary.

    ...

=head1 SUBROUTINES/METHODS

=head2 C<new>

  my $foo = Parse::Crontab::English->new( file => $filename);

Loads the crontab definition contained in the named file, and generates a
summary of each line.

The result is a hash whose key is the command line executed by cron; since
command lines can be duplciated, the value is an AoH, with the hash containing
the base values from Parse::Crontab and the summary containing English
descriptions of when the job will run.

=head2 C<load>

Internal routine, called from C<new>.

=head2 C<hm>

Internal routine, called from C<load> to format hour (and possibly) minutes
into a nice output string.

=head2 Values straight from Parse::Crontab:

=head3 C<mon_range>

The sorted list of months that the job will run. Values range from 1 to 12.

=head3 C<day_range>

The sorted list of days of the month that the job will run. Values range from 1
to 31.

=head3 C<dow_range>

The sorted list of days of the week that the job will run. Values run from 0 to
7, and there may be both 0 and 7 (Sunday).

=head3 C<hour_range>

Ths sorted list of hours that the job will run. Values run from 0 to 23.

=head3 C<min_range>

The sorted list of minutes that the job will run. Values run from 0 to 59.

=head2 Values from Parse::Crontab::English

=head3 C<dow_range>

This is the sorted numeric range of days from 0 to 6. If the original values
where 0-6 or 1-7, this is mapped to 0-6.

=head3 C<days_english>

The same information as the previous field, but using the English names for the
days.  Not everyine knows that 0 is Sunday.

=head3 C<day_name_range>

If all days of the week are selected, this just contains 'every day of the
week', which is usually information that can be discarded. If just one day of
the week is selected, this contains 'just Tuesday' (for example). A list of
days is separated with a comma, and the Oxford Comma is used. So a list will
finish with 'second_to_last, and last'.

If there are several days but they can be gethered into a list, that's also
done. So this list may contain 'Monday to Wednesday, and Friday', for example.

=head3 C<hours_minutes>

If a job is running every minute, this contains 'every minute of the following
hours: ', followed by a list of the hours.

Otherwise, this contains 'at C<list of hours>, at C<list of minutes> after the
hour'.

=head3 C<hm_short>

If a job is running every minute, this short version of 'hours_minutes'
contains 'every minute, for x times, from y to z' where x is how often the job
runs in an hour, y is the first time it runs, and z is the last time it runs.

Otherwise, this contains 'x times daily (y times an hour), starting at z and
ending at w', where x is how many times it runs in total, y is how many times
it runs per hour, z is the first time it runs and w is the last time it runs.

=head3 C<line_num>

This is the line number from the original file -- useful if you want to go and
adjust the crontab after reading the explanation.

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

      #  First, skip everything that Parse::Crontab didn't find useful.

      if ( !exists $line->{ schedule } ) {

        $line_num++;
        next;
      }

      #  Next, save the good stuff.

      push ( @{ $data{ $line->{ command } } },
        { mon_range  => $line->{ schedule }{ month }{ expanded },
          day_range  => $line->{ schedule }{ day }{ expanded },
          dow_range  => $line->{ schedule }{ day_of_week }{ expanded },
          hour_range => $line->{ schedule }{ hour }{ expanded },
          min_range  => $line->{ schedule }{ minute }{ expanded } } );

      #  Get the entry so we have less typing to do. Then, if we see the range
      #  of days is min to max, add 'all days' to the english description. More
      #  to come, obviously.

      my $entry = $data{ $line->{ command } }[ -1 ];

      #  Look at the month.

      my %months = (
        1 => 'January',    2 => 'February', 3 => 'March',     4 => 'April',
        5 => 'May',        6 => 'June',     7 => 'July',      8 => 'August',
        9 => 'September', 10 => 'October', 11 => 'November', 12 => 'December',
      );

      if ( @{ $entry->{ mon_range } } == 12 ) {

        $entry->{ month_desc } = 'every month';

      } elsif ( @{ $entry->{ mon_range } } == 1 ) {

        $entry->{ month_desc } = "just the month of $months{ $entry->{ mon_range }[ 0 ] }";

      } else {

        my $ranges = determine_ranges ( $entry->{ mon_range }, [ sort keys %months ] );

        #  Create a list of months using the ranges we've found.

        my @month_list;
        foreach my $r ( @$ranges ) {

          if ( $r->[ 0 ] == $r->[ 1 ] ) {

            push ( @month_list, $months{ $r->[ 0 ] } );

          } else {

            push ( @month_list, "$months{ $r->[ 0 ] } to $months{ $r->[ 1 ] }" );
          }
        }

        #  Commify the result.

        my $list = join ( ', ', @month_list );
        if ( $list =~ /, / ) {

          $list =~ s/(.+), /$1, and /;
        }

        $entry->{ month_desc } = "the following " . scalar @month_list .  " months: $list";
      }

      #  Look at day of month.

      if ( @{ $entry->{ day_range } } == 31 ) {

        $entry->{ day_desc } = 'every day of the month';

      } elsif ( @{ $entry->{ day_range } } == 1 ) {

        $entry->{ day_desc } = "Just on day $entry->{ day_range }[ 0 ]";

      } else {

        my $ranges = determine_ranges ( $entry->{ day_range }, [ 1 .. 31 ] );

        #  Create a list of days using the ranges we've found.

        my @day_list;
        foreach my $r ( @$ranges ) {

          if ( $r->[ 0 ] == $r->[ 1 ] ) {

            push ( @day_list, $r->[ 0 ] );

          } else {

            push ( @day_list, "$r->[ 0 ]-$r->[ 1 ]" );
          }
        }

        #  Commify the result.

        my $list = join ( ', ', @day_list );
        if ( $list =~ /, / ) {

          $list =~ s/(.+), /$1, and /;
        }

        $entry->{ day_desc } = "the following " . scalar @day_list .  " days: $list";
        if ( $entry->{ day_range } =~ /, / ) {

          $entry->{ day_desc } =~ s/(.+), /$1, and /;
        }
      }

      #  Look at the day of the week

      #  Well, it looks like the parent module sometimes messes up and reads 7
      #  (Sunday) as both 0 and 7 -- meaning that we get two entries, both of
      #  them Sunday. So now I'm going to do some de-duplication on that mess.
      #  One side effect is that I won't have to pop off the last element of
      #  the array, since we'll now have a maximum of seven items.

      # $entry->{ dow_value_range } =
      $entry->{ dow_range } =
        [ uniq ( map { $_ % 7  } @{ $entry->{ dow_range } } ) ];

      my %days = (
        0 => 'Sunday',   1 => 'Monday', 2 => 'Tuesday',  3 => 'Wednesday',
        4 => 'Thursday', 5 => 'Friday', 6 => 'Saturday',
      );

      if ( @{ $entry->{ dow_range } } == 7 ) {

        $entry->{ dow_desc }   = 'every day of the week';

      } elsif ( @{ $entry->{ dow_range } } == 1 ) {

        $entry->{ dow_desc }   = 'just on ' . $days{ $entry->{ dow_range }[ 0 ] };

      } else {

        my $ranges = determine_ranges ( $entry->{ dow_range }, [ sort keys %days ] );

        #  Create day_name_range using the ranges we've found.

        my @day_list;
        foreach my $r ( @$ranges ) {

          if ( $r->[ 0 ] == $r->[ 1 ] ) {

            push ( @day_list, $days{ $r->[ 0 ] } );

          } else {

            push ( @day_list, "$days{ $r->[ 0 ] } to $days{ $r->[ 1 ] }" );
          }
        }

        $entry->{ dow_desc } = "the following " .
          ( scalar @{ $entry->{ dow_range } } ) . " days of the week: " .
          join ( ', ', @day_list );

        if ( $entry->{ dow_desc } =~ /, / ) {

          $entry->{ dow_desc } =~ s/(.+), /$1, and /;
        }
      }

      #  If it's every minute, then just show that, plus the hours.

      my $hours = join ( ', ', map { "${_}h00" } @{ $entry->{ hour_range } } );
      if ( $hours =~ /, / ) { $hours =~ s/(.+), /$1, and /; }

      if ( @{ $entry->{ min_range } } == 60 ) {

        $entry->{ hours_minutes } = "every minute of the following hours: $hours";

        #  Later, we can convert the 24 hour values to am/pm if necessary. Or I
        #  might have a function that takes the hour and minute and returns an
        #  appropriately formatted time. (There's a bit of copy-pasta going on
        #  here, obviously.)

        $entry->{ hm_desc } = "every minute, for " .
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

          $entry->{ hm_desc } = "Once, at " .
            hm ( $entry->{ hour_range }->[ 0 ], $entry->{ min_range }->[ 0 ] );

        } else {

          $entry->{ hm_desc } = "$times times daily (" .
            ( scalar @{ $entry->{ min_range } } ) . " times an hour), starting at " .
            hm ( @{ $entry->{ hour_range } }[  0 ], @{ $entry->{ min_range } }[   0 ] ) .
            ", and ending at " . 
            hm ( @{ $entry->{ hour_range } }[ -1 ], @{ $entry->{ min_range } }[  -1 ] );

          $entry->{ hm_desc } =~ s/\(1 times/(once/;   #  Ugh, English.
          $entry->{ hm_desc } =~ s/\(2 times/(twice/;  #  Ugh, English.
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

#  Figure out the ranges from a set of values.

sub determine_ranges
{
    my ( $input_range, $possible_values ) = @_;

    #  Original comment when this code was just for ranges of days: For my next
    #  trick, I'm going to see if I can reduce the list to a range, in order to
    #  map 1-5 to Monday to Friday. All we know about the list of day numbers
    #  is that they're ordered.

    my ( $first, $last, @ranges );

    foreach my $off ( 0 .. ( scalar @$possible_values ) - 1 ) {

      my $this = $input_range->[ $off ];
      if ( !defined $this ) { next; }

      if ( defined $first ) {

        if ( defined $last ) {

          if ( $last + 1 == $this ) {

            #  We're still in order, continue.

            $last = $this;

          } else {

            #  Not in order -- need to close off previous order and start a new one.

            push ( @ranges, [ $first, $last ] );

            $first = $this;
            undef $last;
          }
          
        } else {

          if ( $first + 1 == $this ) {

            #  We're still in order, continue.

            $last = $input_range->[ $off ];

          } else {

            #  Not in order -- need to close off previous order and start a new one.

            push ( @ranges, [ $first, $first ] );
            $first = $input_range->[ $off ];
          }
        }

      } else {

        $first = $input_range->[ $off ];
      }
    }

    #  We may need to capture the last range ..

    if ( @ranges == 0 || defined $first ) {

      if ( defined $last ) {

        push ( @ranges, [ $first, $last ] );

      } else {

        push ( @ranges, [ $first, $first ] );
      }
    }

    return ( \@ranges );
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
