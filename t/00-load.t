#!perl 
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'XMMSAS::Extract' ) || print "Bail out!\n";
    use_ok( 'XMMSAS::Detect' ) || print "Bail out!\n";
}

diag( "Testing XMMSAS::Extract $XMMSAS::Extract::VERSION, Perl $], $^X" );
