#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Parse::Crontab::English' ) || print "Bail out!\n";
}

diag( "Testing Parse::Crontab::English $Parse::Crontab::English::VERSION, Perl $], $^X" );
