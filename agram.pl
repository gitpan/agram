#! usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use List::MoreUtils qw( uniq all );
use Carp            qw( croak    );
use Fcntl           qw( SEEK_SET );

our $VERSION = '0.8.5';

my $DEFAULT_DICTIONARY = "/usr/share/dict/words";
my $USAGE = <<"USAGE";
Usage: agram [-s <word(s)>] [c <words>] [-obq] [-d <dictionary file>]

Options:
\t-s, --search\tSpecify words to search for anagrams for.
\t-c, --compare\tSpecify words to check against eachother.
\t-o, --one\tFind only the first anagram and exit.
\t-b, --base\tUse only base letters, ignoring length and letter count.
\t-q, --quiet\tDon't print status messages, useful for feeding to other programs.
\t-d, --dict\tSpecify a dictionary file. Defaults to $DEFAULT_DICTIONARY.
USAGE

sub USAGE {
	print $USAGE;
	exit;
}

################
# Get options. #
my $dict_file = $DEFAULT_DICTIONARY;
my ($only_find_one, $use_base_letters, $quiet, @compare_words, @search_words);

GetOptions(
	'dict|d=s'          => \$dict_file,
	'one|o'             => \$only_find_one,
	'base|b'            => \$use_base_letters,
	'quiet|q'           => \$quiet,
	'search|s=s{,}'     => \@search_words,
	'compare|c=s{1,2}'  => \@compare_words,
	#'help|h'           => \&USAGE(),
);

USAGE() if (!@search_words && !@compare_words);

#######################
### COMPARISON CODE ###
#######################

if (@compare_words) {
	my %comparison_letters = map { $_ => join "", pieces($_) } @compare_words;
	
	if ($comparison_letters{ $compare_words[0] } 
		eq $comparison_letters{ $compare_words[1] }) 
	{
		print "yes\n";
	}
	else {
		print "no\n";
	}
	
	exit;
}

#######################
##### SEARCH CODE #####
#######################

####################################
# Sanity check and set up our data #
croak sprintf "Can't find anagram of single-letter words"
	if all { length $_ <= 1 } @search_words;

my $search_count = scalar @search_words;

my %search_letters; 
%search_letters = map { $_ => join "", pieces($_) } @search_words;

my %anagrams;
@anagrams{@search_words} = ();


open (my $DICT, "<", $dict_file) or croak "Can't open dictionary file $dict_file";

SEARCH_WORD:
for my $search_word (@search_words) {
	
	my $search_letters = $search_letters{$search_word};
	
	if (tell $DICT > 0) {
		seek($DICT, 0, SEEK_SET);
	}
	
	$search_count--;
	
	if (length $search_word <= 1) {
		status(sprintf("Skipping $search_word -- $search_count word%s left\n", 
			$search_count == 1 ? q{} : q{s}));
		
		next SEARCH_WORD; 
	}
	
	status(sprintf("Now searching for $search_word -- $search_count word%s left\n",
		$search_count == 1 ? q{} : q{s}));
	
	POS_WORD:
	while (defined (my $possible_word = <$DICT>)) {
		chomp $possible_word;
			
		next POS_WORD if length $search_letters > length $possible_word;
		
		if (!$use_base_letters) {
			# This next clause makes this run a *lot* faster
			next POS_WORD if length $possible_word != length $search_word;
		}
	
		my $possible_letters = join("", pieces($possible_word));
	 
		if ($search_letters eq $possible_letters) {	
		
			push @{ $anagrams{$search_word} }, $possible_word;
			
			# once we find the first anagram we're done if the -o option is invoked.
			last POS_WORD if $only_find_one; 
		}
	
	
	}

}

close $DICT;

status("Done\n\n");
dump_results();

### Subs beyond this point ###

sub dump_results {
	for my $word (keys %anagrams) {
		if (!defined $anagrams{$word}) {
			print "0 anagrams found for $word\n";
			next;
		}
		
		my $anagrams = \@{ $anagrams{$word} };
		my $anagram_count = scalar @$anagrams;
		
		print "$word $anagram_count: ", 
			join(q{ }, @$anagrams ? @$anagrams : ());
		print "\n";
			
	}
}

sub pieces {
	my ($word) = @_;
	
	my @pieces = split //, $word;
	@pieces    = sort { lc($a) cmp lc($b) } @pieces;
	
	return $use_base_letters ? uniq @pieces : @pieces;		
}

sub status {
	return if $quiet;
	print @_;
}

__END__

=head1 NAME

agram - Basic anagrammer

=head1 VERSION

This documentation refers to agram version 0.85.

=head1 USAGE

agram -s scare
> scare 5: carse caser ceras scare scrae

agram -s scare -d /custom/dictionary/file

agram -s scare -b
> scare 21: accerse accresce ascare caress caresser carse caser ceras crease creaser reaccess recase recrease resaca scarce scare scarer scarrer scrae searce searcer

agram -c pear pare
> yes

=head1 REQUIRED ARGUMENTS

=over 4

=item -s word(s)

Specify one or more words to search for. Will find every anagram of each word and print them out.

=item -c words

Specify two words to compare. Prints C<yes> if they are anagrams or C<no> if they aren't. If this option is specified it will take precedence over -s, and the words given after -s will be ignored.

=back

=head1 OPTIONS

=over 4

=item -d

Invoking agram with the -d option allows the user to set a custom dictionary file for the program to search through. The dictionary file will default to /usr/share/dict/words.

=item -b

Invoking agram with the -b option ignores the length of the search word and the words in the dictionary file, instead matching simply by their base letters. 
In other words, when used with the word B<pear>, any word that consists only of the letters B<a>, B<e>, B<p>, and B<r> will be matched. 
This is considerably slower than a normal anagram match because agram must consider every single word rather than skipping based on length, but will be fixed in the future.

=item -o

Invoking agram with the -o option returns only the first anagram found. It can be used with any of the search flags.

=item -q

Quiet mode - doesn't print status messages as it is searching the dictionary file. This option is primarily intended for feeding the output of this program to another program. The output format is:
<word> <number of anagrams found>: <space separated list of anagrams>

=back

=head1 DESCRIPTION

agram is an anagrammer, or a program that finds the anagrams of words given to it. If two words are anagrams, they consist of the same letters and each letter occurs the same amount of times. While agram goes beyond this functionality with the -b flag, its main purpose is still to find anagrams.

=head1 DIAGNOSTICS

=over 4

=item Usage message

Either agram was invoked with the -h or --help option, or you forgot to provide either words to compare (see L<-c>) or words to search (seeL<-s>)!

=item Can't find anagrams of single letter words

Every word you provided for -c or -s had one letter or less, meaning there are no anagrams.

=item Can't open dictionary_file %s

The dictionary file that was provided or the default one was not able to be opened for reading. Make sure you have the pathname correct and that this script has read permission.

=back

=head1 DEPENDENCIES

Requires version and List::MoreUtils.

=head1 BUGS AND LIMITATIONS

agram can't piece together complex new sentences or phrases based on seed words. Unfortunately, agram cannot speak english and therefore leaves the really clever anagram stuff up to the humans. :(

A small bug at the moment is the inability to group command line flags. For some reason, some things like "-ob" are triggering an "unknown option: -ob" warning rather than parsing as separate options. This is something wrong with Getopt::Long. So for now if you want to use -o and -b or any other combination you have to do it the long way:
C<agram -s scare -o -b>

=head1 TODO

=over 4

=item Optimize

Optimize, optimize, optimize, optimize. Especially when running under the -b flag.

=back

=head1 AUTHOR

Lincoln Ombelets C<< <ch.animalbar@gmail.com> >>

=head1 LICENSE & COPYRIGHT

Copyright 2009 Lincoln Ombelets, all rights reserved.
This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.