use Test::More;
use Test::Differences;

# First Tests check to make sure we have the same output as Algorithm::Diff.
use Algorithm::Diff qw(diff);
use Text::SemanticDiff qw(sdiff semantic_diff);

my @test1 = qw(a b c);
my @test2 = qw(a b c);

my @expected = diff( \@test1, \@test2 );
my @result = semantic_diff( \@test1, \@test2 );

eq_or_diff( \@result, \@expected, 'Identical - Alogrithm::Diff' );

# Test 2
@test1 = qw(a c);
@test2 = qw(a b c);

@expected = diff( \@test1, \@test2 );
@result = semantic_diff( \@test1, \@test2 );

# We verify sdiff is working here a moment.
eq_or_diff( \@result, \@expected, 'Add one - Alogrithm::Diff' );
@result = sdiff( \@test1, \@test2 );
eq_or_diff( \@result, \@expected, 'sdiff of Add one.' );

# Test 3
@test1 = qw(a b c);
@test2 = qw(a c);

@expected = diff( \@test1, \@test2 );
@result = semantic_diff( \@test1, \@test2 );

eq_or_diff( \@result, \@expected, 'Remove one - Algorithm::Diff' );

# Test 4
@test1 = qw(a b c);
@test2 = qw(a c c);

@expected = diff( \@test1, \@test2 );
@result = semantic_diff( \@test1, \@test2 );

eq_or_diff( \@result, \@expected, 'Change one - Algorithm::Diff' );

# Test 5 - Long sequence.
@test1 = qw(a b c e h j l m n p);
@test2 = qw(b c d e f j k l m r s t);

@expected = diff( \@test1, \@test2 );
@result = semantic_diff( \@test1, \@test2 );

eq_or_diff( \@result, \@expected, 'Long Sequence - Algorithm::Diff' );

@test1 = ( 'a', 'b', 'c', 'Hello there', 'd' );
@test2 = ( 'a', 'b', 'e', 'Hello there', 'd' );

@expected = diff( \@test1, \@test2 );
@result = semantic_diff( \@test1, \@test2 );

eq_or_diff( \@result, \@expected, 'Words 1 - Algorithm::Diff' );

@test1 = ( 'a', 'b', 'c', 'Hello there', 'd' );
@test2 = ( 'a', 'b', 'c', 'Hello Miss',  'd' );

@expected = diff( \@test1, \@test2 );
@result = semantic_diff( \@test1, \@test2 );

eq_or_diff( \@result, \@expected, 'Words 2 - Algorithm::Diff' );

# (Note that changing two lines may not be the same as Algorithm::Diff - we sort the changes!)

#
# Ok, done testing the 'Does it work like Algorithm::Diff' section.
#

@test1 = ( 'a', 'b', 'c', 'Hello there', 'd' );
@test2 = ( 'a', 'b', 'c', 'Hello, Miss', 'd' );

@expected = [ [
       '!', 3,[ [ [ '-', 0, 'Hello there' ],
                  [ '+', 0, 'Hello,' ],
                  [ '+', 1, ' Miss' ]
                  ] ]
             ] ];

@result = semantic_diff( \@test1, \@test2 );

eq_or_diff( \@result, \@expected, 'First sub-change.' );


# Test multiple changes in a line.
@test1 = ( 'a', 'b', 'c', 'Hello, there, Daniel', 'd' );
@test2 = ( 'a', 'b', 'c', 'Hi, there, Nora', 'd' );

@expected = [ [
       '!', 3,[ [ [ '-', 0, 'Hello,' ],
                  [ '+', 0, 'Hi,' ], ],
                [ [ '-', 2, ' Daniel' ],
                  [ '+', 2, ' Nora' ]
                  ] ]
             ] ];

@result = semantic_diff( \@test1, \@test2 );

eq_or_diff( \@result, \@expected, 'Multiple sub-changes.' );

# Test multiple changes in a line.
@test1 = ( 'a', 'b', 'c', 'Hello, there, Daniel', 'd' );
@test2 = ( 'a', 'e', 'c', 'Hi, there, Nora', 'd' );

@expected = (
              [ [ '-', 1, 'b' ], [ '+', 1, 'e' ] ],
              [ [ '!', 3,
                    [
                    [ [ '-', 0, 'Hello,' ],  [ '+', 0, 'Hi,' ], ],
                    [ [ '-', 2, ' Daniel' ], [ '+', 2, ' Nora' ] ]
                    ]
                ] ]
            );

@result = semantic_diff( \@test1, \@test2 );

eq_or_diff( \@result, \@expected, 'Changes and sub-changes.' );

done_testing();