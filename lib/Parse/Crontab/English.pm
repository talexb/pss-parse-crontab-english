package Parse::Crontab::English;

use 5.006;
use strict;
use warnings;

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
      if ( @{ $entry->{ day_range } } == 31 ) {

        $entry->{ days_english } = 'every day of the month';
      }

      #  Check Day of Week .. (Both 0 and 7 are present -- so 8 entries)

      if ( @{ $entry->{ dow_range } } == 8 ) {

        $entry->{ dow_english } = 'every day of the week';
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
          @{ $entry->{ hour_range } }[  0 ] . "h00 to " .
          @{ $entry->{ hour_range } }[ -1 ] . "h00";

      } else {

        #  We're going to show the hours and minutes in a list. The shorter
        #  version follows.

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

          $entry->{ hm_short } = "Once, at $entry->{ hour_range }->[ 0 ]h" .
            sprintf ( "%02d", $entry->{ min_range }->[ 0 ] );

        } else {

          $entry->{ hm_short } = "$times times, starting at " .
            @{ $entry->{ hour_range } }[  0 ] . "h" .
            sprintf ( "%02d", @{ $entry->{ min_range } }[  0 ] ) .
            ", and ending at " . 
            @{ $entry->{ hour_range } }[ -1 ] . "h" .
            sprintf ( "%02d", @{ $entry->{ min_range } }[ -1 ] );
        }
      }

      #  Add line number ..

      $data{ $line->{ command } }->[ -1 ]{ line_num } = $line_num++;
    }
    $self->{ summary } = \%data;
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
