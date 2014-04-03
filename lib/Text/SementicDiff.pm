package Text::SementicDiff;
use strict;
use warnings;
use 5.10.0;   # The '//' operator requires 5.10 or greater.

use Algorithm::Diff qw(diff);

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = '0.01';
    @ISA     = qw(Exporter);

    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw(sdiff);
    @EXPORT_OK   = qw(sementic_diff sdiff);
    %EXPORT_TAGS = ();
} ## end BEGIN

#################### subroutine header begin ####################

=head2 sample_function

 Usage     : How to use this function/method
 Purpose   : What it does
 Returns   : What it returns
 Argument  : What it wants to know
 Throws    : Exceptions and other anomolies
 Comment   : This is a sample subroutine header.
           : It is polite to include more pod and fewer comments.

See Also   :

=cut

#################### subroutine header end ####################

sub sdiff { sementic_diff(@_); }

sub sementic_diff {
    my @old   = @{ $_[0] };
    my @new   = @{ $_[1] };
    my $regex = $_[2] // '\p{Punct}';

    # First, do a basic diff the old way.
    my @base_diff = diff( \@old, \@new );

    # An array to store the semantic changes.
    my @semetic_diff;

# Step through the diff.
# If the chunk is only one line long, it's not a modify, and we can skip the rest.
    foreach my $chunk (@base_diff) {
      next if @{$chunk} == 1;

        # Find paired delete-inserts.
        # They will always be two elements with matching line numbers in a row.
        my $last;
        foreach my $line ( @{$chunk} ) {
          next unless $$line[1] == $$last[1];

            # Split the old and new lines into sections.
            my @old_line = split m/$regex/, @$last;
            my @new_line = split m/$regex/, @$line;

            # Diff the two lines.
            my $diff_ref = diff( \@old_line, \@new_line );

            # Save it into the array of changes.
            # Indexed into the @sementic_diff array, for easer access later.
            $sementic_diff[ $$line[1] ] = $diff_ref;
        } ## end foreach my $line ( @{$chunk...})
        continue { $last = $line; } # Save a copy of the line for the next time.
    } ## end foreach my $chunk (@base_diff)

    # Now to create a unified diff array...
    my @result_diff;

    foreach my $chunk (@base_diff) {

        # Single adds or deletes just copy over.
        if ( @$chunk == 1 ) {
            push @result_diff, $chunk;
        }
        else {
            # We build a new array of changes for the rest.
            my @new_chunk;
            foreach my $line (@$chunk) {

                # If we have a change for this line,
                # then copy it over instead of the new line.
                if (
                    defined( $sementic_diff[ $$line[1] ] ) {

                        # No doubles - Only once, on the 'add'.
                        if ( $$line[0] eq '+' ) {
                            push @new_chunk,
                              ( '!', $$line[1], $sementic_diff[ $$line[1] ] );
                        }
                    } else    # If we do *not* have an inside-line diff.
                    {
                        push @new_chunk, @$line;
                    }
                } ## end foreach my $line (@$chunk)

                # Now write the new chunk to the results.
                push @result_diff, @new_chunk;
            } ## end else [ if ( @$chunk == 1 ) ]
        } ## end foreach my $chunk (@base_diff)

      return @result_diff;
    } ## end sub sementic_diff

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module.
## You better edit it!

=head1 NAME

Text::SementicDiff - Creates Sementic Diffs of Text files.

=head1 SYNOPSIS

  use Text::SementicDiff;
  blah blah blah


=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



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

perl(1).

=cut

#################### main pod documentation end ###################

    1;

# The preceding line will help the module return a true value