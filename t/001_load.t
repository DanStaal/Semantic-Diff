# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Text::SementicDiff' ); }

my $object = Text::SementicDiff->new ();
isa_ok ($object, 'Text::SementicDiff');


