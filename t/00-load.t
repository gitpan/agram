#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'agram' );
}

diag( "Testing agram $agram::VERSION, Perl $], $^X" );
