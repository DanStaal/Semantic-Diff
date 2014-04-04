package Text::SemanticDiff;
use strict;
use warnings;
use 5.10.0;    # The '//' operator requires 5.10 or greater.

use Algorithm::Diff qw(diff);

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = '0.01';
    @ISA     = qw(Exporter);

    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw(sdiff);
    @EXPORT_OK   = qw(semantic_diff sdiff separator);
    %EXPORT_TAGS = ();
} ## end BEGIN

my $default_regex = '\p{Punct}';

sub separator { return $default_regex }

sub sdiff { semantic_diff(@_); }

sub semantic_diff {
    my @old   = @{ $_[0] };
    my @new   = @{ $_[1] };
    my $regex = $_[2] // $default_regex;

    # First, do a basic diff the old way.
    my @base_diff = diff( \@old, \@new );

    # An array to store the semantic changes.
    my @semantic_diff;

    # Step through the diff.
    # If the chunk is only one line long,
    # it's not a modify, and we can skip the rest.
    foreach my $chunk (@base_diff) {
      next if @$chunk == 1;

        # Sort the list...  (It's not?)
        {
            use sort 'stable';
            @$chunk = sort { $a->[1] <=> $b->[1] } @$chunk;
        }

        # Find paired delete-inserts.
        # They will always be two elements with matching line numbers in a row.
        my $last = [ undef, '-1', undef ];
        foreach my $line ( @{$chunk} ) {
          next unless $$line[1] == $$last[1];

            # Split the old and new lines into sections.
            my @old_line = split qr/(?<=$regex)/o, $$last[2];
            my @new_line = split qr/(?<=$regex)/o, $$line[2];

            # If they split into full-lines, keep the original.
          next if ( @old_line == 1 and @new_line == 1 );

            # Diff the two lines.
            my @diff_ref = diff( \@old_line, \@new_line );

            # Sort the diff - because we know it's not...
            foreach my $block (@diff_ref) {
                use sort 'stable';
                @$block = sort { $a->[1] <=> $b->[1] } @$block;
            }

            # Save it into the array of changes.
            # Indexed into the @semantic_diff array, for easer access later.
            $semantic_diff[ $$line[1] ] = \@diff_ref;
        } ## end foreach my $line ( @{$chunk...})
        continue { $last = $line; } # Save a copy of the line for the next time.
    } ## end foreach my $chunk (@base_diff)

    # Now to create a unified diff array...
    my @result_diff;

    foreach my $chunk (@base_diff) {

        # Single adds or deletes just copy over.
        if ( @$chunk == 1 ) {
            push @result_diff, \@$chunk;
        }
        else {
            # We build a new array of changes for the rest.
            my @new_chunk;
            foreach my $line (@$chunk) {

                # If we have a change for this line,
                # then copy it over instead of the new line.
                if ( defined( $semantic_diff[ $$line[1] ] ) ) {

                    # No doubles - Only once, on the 'add'.
                    if ( $$line[0] eq '+' ) {
                        push @new_chunk,
                          [ '!', $$line[1], $semantic_diff[ $$line[1] ] ];
                    }
                } ## end if ( defined( $semantic_diff...))
                else    # If we do *not* have an inside-line diff.
                {
                    push @new_chunk, $line;
                }
            } ## end foreach my $line (@$chunk)

            # Now write the new chunk to the results.
            push @result_diff, [@new_chunk];
        } ## end else [ if ( @$chunk == 1 ) ]
    } ## end foreach my $chunk (@base_diff)

  return wantarray ? @result_diff : \@result_diff;
} ## end sub semantic_diff

=head1 NAME

Text::SemanticDiff - Creates Semantic Diffs of Text files.

=head1 SYNOPSIS

  use Text::SemanticDiff;

  my @diff = sdiff(/@old, /@new);

=head1 DESCRIPTION

Standard diffs have the problem of being line-oriented.  While this works well for
code, it doesn't work as well in natural language files.  This module attempts to
do a slightly better job: It first compares in the normal line-oriented fashion,
then compares inside the line on semantic elements: subclauses and phrases, delineated
by punctuation.  The most basic semantic element would be a sentence.  (Ending with a
period.)

The interface and output format is similar to Algorithm::Diff, to the point that on a
purely line-oriented file (where there is only one semantic element per line) it should be
identical.

=head1 USAGE

=over

=item semantic_diff( \@, \@, $ )

=item sdiff( \@, \@, $ )

C<sdiff()> is just a wrapper around C<semantic_diff()> - it's convenient to have the shorter name.

The main comparison function: It takes two or three arguments. The first two must
be references to the lists of items to be compared.  The optional third is a
regular expression string to be used to separate semantic elements.  (The default is
to use the C<\p{Punct}> character class.  See L<perlrecharclass> for details.)

Returns a list with the smallest set of changes needed to convert the first list
into the second.  The list is a set of hunks: Each hunk is a set of contiguous lines
that need to be added, deleted, or replaced.  Each line in the hunk may have contain
it's own list of hunks that were separated semantically.

It's probably easier to give an example.  The following two lists:

    ( 'a', 'b', 'c', 'Hello, there, Dick', 'd' )
    ( 'a', 'e', 'c', 'Hi, there, Jane', 'd' )

Produce the following output:

    (
      [ [ '-', 1, 'b' ], [ '+', 1, 'e' ] ],
      [ [ '!', 3,
            [
            [ [ '-', 0, 'Hello,' ],  [ '+', 0, 'Hi,' ], ],
            [ [ '-', 2, ' Dick' ], [ '+', 2, ' Jane' ] ]
            ]
        ] ]
    )

The first hunk is the second item the the lists (array position '1').  We remove the initial
value 'b' (-) and replace (+) it with 'e'.

The second hunk is the fourth item in the lists; it has been broken down into subelements (!).
(Poorly: The grammar is atrocious...)  Of those subelements, we have two hunks: The first
first subelement of the phrase, where we delete 'Hello,' and replace it with 'Hi,'.  The
second hunk is the third subelement of the phrase, where we replace ' Dick' with ' Jane'.
(Note that whitespace is conserved, and considered part of the I<following> hunk.)

C<sdiff()> is exported by default.  The other functions are not.

=item separator()

Returns the default separator regular expression used to sperate semantic chunks.  As noted
above that's currently C<\p{Punct}>, but if you need it in your code it is best to get
it here, in case that needs to change in the future.

=back

=head1 BUGS

I haven't checked every edge case yet: This module attempts to prefer adding and replacing
whole lines to breaking the lines up when applicable, but there may be cases where it doesn't.

I'm not sure how well C<wantarray> propagates through callers.  This should return a reference
to the list when called in scalar context, but again it hasn't been fully tested.

=head1 HISTORY

0.01 Thu Apr  3 16:58:12 2014
    - original version; created by ExtUtils::ModuleMaker 0.51


=head1 AUTHOR

    Daniel T. Staal
    CPAN ID: DStaal
    DStaal@usa.net

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Algorithm::Diff>

This module was partially inspired by an article by Brandon Rhodes on
Semantic Linefeeds: L<http://rhodesmill.org/brandon/2012/one-sentence-per-line/>

=cut

1;

# The preceding line will help the module return a true value