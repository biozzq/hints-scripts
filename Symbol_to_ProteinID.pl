#!/usr/bin/perl -w
use strict;
die "Usage:perl $0 <feature table> <GeneSymbol> <Pro.fasta> <Output link> <Output Pro.fa>\n" unless @ARGV == 5;
my $input = $ARGV[0];
open (FEATURE,($input =~ /\.gz$/)? "gzip -dc $input |" : $input) or die "gzipped feature table required!\n";
my $storefile = &FastaReader($ARGV[2]) or die "fasta file is required!\n";
my %symbol;
while (<FEATURE>){
	chomp;
	my @inf = split/\t/;
	$symbol{$inf[14]} = $inf[10];
}
close FEATURE;
open (NAME, "$ARGV[1]") or die "gene symbol missing!\n";
open (OUT, ">$ARGV[3]") or die "link permission denied!\n";
open (FASTA, ">$ARGV[4]") or die "Protein fasta file writing failed!\n";
my $match = 0;
my $unmatch = 0;
while (<NAME>){
	chomp;
	if (exists $symbol{$_}){
		$match++;
		print OUT $_,"\t",$symbol{$_},"\n";
		if (defined $storefile->{$symbol{$_}}){
			my $seq = $storefile->{$symbol{$_}};
			next unless length($seq) > 1;
			print FASTA ">$symbol{$_}\n";
			if (length($seq) > 100){
			my @tmp_seq = $seq =~ /\w{100}/g;
				if (length($') > 0){
					print FASTA join "\n",(@tmp_seq, $', "");
				}
				else{
					print FASTA join "\n",(@tmp_seq, "");
				}
			}
			else{
				print FASTA $seq,"\n";
			}
		}
		else{
			print STDERR "$_ $symbol{$_} not in protein database\n";
		}
	}
	else{
		$unmatch++;
		print STDERR $_,"\n";
	}
}
close NAME;
close OUT;
close FASTA;
print STDERR "match:$match\nunmatch:$unmatch\n";

sub FastaReader {
	my ($file) = @_;
	open (IN, ($file =~ /\.gz$/)? "gzip -dc $file |" : $file) or die "Fail to open file: $file!\n";
	local $/ = '>';
	<IN>;
	my ($head, $seq, %hash);
	while (<IN>){
		s/\r?\n>?$//;
		( $head, $seq ) = split /\r?\n/, $_, 2;
		my $tmp = (split/\s+/,$head)[0];
		$seq =~ s/\s+//g;
		$hash{$tmp} = $seq;
	}
	close IN;
	$/ = "\n";
	return \%hash;
}
