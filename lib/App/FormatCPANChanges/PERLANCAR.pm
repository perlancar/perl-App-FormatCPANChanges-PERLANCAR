package App::FormatCPANChanges::PERLANCAR;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use List::Util qw(max);
use Sort::Sub qw(changes_group_ala_perlancar);

our %SPEC;

$SPEC{format_cpan_changes_perlancar} = {
    v => 1.1,
    summary => 'Format CPAN Changes a la PERLANCAR',
    description => <<'_',

* No preamble.

* Each change is formatted as a separate paragraph (or set of paragraphs).

_
    args => {
        file => {
            schema => 'str*',
            summary => 'If not specified, will look for a file called '.
                'Changes/ChangeLog in current directory',
            pos => 0,
        },
    },
};
sub format_cpan_changes_perlancar {
    require App::ParseCPANChanges;
    #require DateTime::Format::Alami::EN;
    require Text::Wrap;

    my %args = @_;

    my $res = App::ParseCPANChanges::parse_cpan_changes(file => $args{file});
    return $res unless $res->[0] == 200;

    # parse dates and sort releases
    my @rels;
    for my $v (keys %{ $res->[2]{releases} }) {
        my $rel = $res->[2]{releases}{$v};
        # $rel->{_parsed_date} = # assume _parsed_date is already YYYY-MM-DD
        push @rels, $rel;
    }
    @rels = sort { $b->{_parsed_date} cmp $a->{_parsed_date} } @rels;

    # determine the width for version
    my @versions = sort keys %{ $res->[2]{releases} };
    my $v_width = 1 + max map { length } @versions;
    $v_width = 8 if $v_width < 8;

    my $chgs = "";

    # render
    local $Text::Wrap::columns = 80;
    for my $rel (@rels) {
        $chgs .= "\n" if $chgs;

        $chgs .= sprintf "%-${v_width}s%s%s\n\n",
            $rel->{version}, $rel->{_parsed_date}, $rel->{note} ? " $rel->{note}" : "";
        for my $heading (sort {changes_group_ala_perlancar($a,$b)} keys %{ $rel->{changes} }) {
            $chgs .= sprintf "%s%s\n\n", (" " x $v_width), "[$heading]"
                if $heading;
            my $group_changes = $rel->{changes}{$heading};
            for my $ch (@{ $group_changes->{changes} }) {
                $ch .= "." unless $ch =~ /\.$/;
                $chgs .= Text::Wrap::wrap(
                    (" " x $v_width) . "- ",
                    (" " x ($v_width+2)),
                    "$ch\n",
                ) . "\n";
            }
        }
    }

    [200, "OK", $chgs];
}

1;
# ABSTRACT:

=cut
