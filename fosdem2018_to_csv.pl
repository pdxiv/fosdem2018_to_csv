#!/usr/bin/perl
use strict;
use warnings;
use LWP::Simple;
use HTML::TreeBuilder::XPath;
our $VERSION = '1.0.0';

# Download schedule
my $html = get('https://fosdem.org/2018/schedule/events/')
  or die 'Unable to get page';

# Parse schedule
my $tree = HTML::TreeBuilder::XPath->new;
$tree->ignore_unknown(0);
$tree->parse($html);
$tree->eof;

# Extract column headers
my @table_heading = $tree->findnodes('//table//thead//tr//th');
my @header_text;
if ( scalar @table_heading == 7 ) {
    pop @table_heading;    # remove last "video" column
    push @header_text, 'devroom';
    foreach (@table_heading) {
        push @header_text, $_->as_text;
    }
    print join( q{;}, @header_text ) . "\n";
}

# Extract columns from schedule
my @table_line   = $tree->findnodes('//table//tr');
my $devroom_text = q{};
foreach my $line (@table_line) {
    my @devroom = $line->findnodes('td[@colspan]');
    if ( scalar @devroom == 1 ) {
        $devroom_text = $devroom[0]->as_text;
        $devroom_text =~ s/\s+\(\d+\)$//;
        $devroom_text =~ s/\s+devroom$//;    # unnecessarily verbose
    }
    my @column_content = $line->findnodes('td[not(@*)]');
    if ( scalar @column_content == 7 ) {
        pop @column_content;                 # remove last "video" column
        my @columns;
        push @columns, $devroom_text;
        foreach (@column_content) {
            my $text_cell = $_->as_text;
            $text_cell =~ s/;/ /g;           # sanitize csv separator
            push @columns, $text_cell;
        }
        print join( q{;}, @columns ) . "\n";
    }
}
