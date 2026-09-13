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
    foreach my $line ( @{ $self->{ base }{ entries } } ) {

      push ( @{ $data{ $line->{ command } } },
        { day_range  => $line->{ schedule }{ day }{ range },
          dow_range  => $line->{ schedule }{ day_of_week }{ range },
          hour_range => $line->{ schedule }{ hour }{ range },
          min_range  => $line->{ schedule }{ min }{ range },
          mon_range  => $line->{ schedule }{ mon }{ range } } );

      #  Get the entry so we have less typing to do. Then, if we see the range
      #  of days is min to max, add 'all days' to the english description. More
      #  to come, obviously.

      my $entry = $data{ $line->{ command } }[ -1 ];
      if ( $entry->{ day_range }->[ 0 ] ==  1 &&
           $entry->{ day_range }->[ 1 ] == 31 ) {

        $entry->{ days_english } = 'all days';
      }
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
