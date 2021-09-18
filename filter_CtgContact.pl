#!/usr/bin/perl

=head1 Name

filter_CtgContact.pl  -- filter the .CtgContact file derived from ctgContact_from_maxBinContacts.pl

=head1 Description

Filter the lines that not included in the input contig list file, and filter
those lines with distanceToEnd values larger than a give cutoff
Sort the lines by the contig contact value

=head1 Version

  Author: Fan Wei, fanwei@caas.cn
  Version: 1.0,  Date: 2021/7/6
  Note:

=head1 Usage
  
  filter_CtgContact.pl [options] <contig_length_file> <Contig_contact_tabular_file>
  --disttoend <int>   the distance cutoff for the considered bin to head bin or tail bin, default=infinite
  --verbose   output running progress information to screen  
  --help      output help information to screen  

=head1 Exmple


=cut

use strict;
use Getopt::Long;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname); 
use Data::Dumper;


##get options from command line into variables and set default values

my $DistToEnd_cutoff;
my ($Verbose,$Help);
GetOptions(
	"disttoend:i"=>\$DistToEnd_cutoff,
	"verbose"=>\$Verbose,
	"help"=>\$Help
);
$DistToEnd_cutoff ||= 1000000000;
die `pod2text $0` if (@ARGV == 0 || $Help);

my $Contig_used_file = shift;
my $CtgContact_file = shift;

my %UsedContigs;
my @Contacts;


##only do statistics for contigs included in $Contig_used_file
open IN, $Contig_used_file || die "fail open $Contig_used_file \n";
while (<IN>) {
	if(/(\S+)\s+(\d+)/){
		my $ctgId = $1;
		my $ctgLen = $2;
		$UsedContigs{$ctgId} = $ctgLen;

	}
}
close IN;


##this file is generated by ctgContact_from_maxBinContacts.pl
##To get the max Hic conatact count for each contig ends
open IN, $CtgContact_file || die "fail open $CtgContact_file\n";;
while (<IN>) {
	next if(/^\#/);
	chomp;
	my @t = split /\s+/;
	my $ctg1 = $t[0]; 
	my $ctg2 = $t[1]; 
	my $contact = $t[2]; 
	my $ctg1Pos = $t[3]; 
	my $ctg2Pos= $t[4]; 
	my $ctg1PosDist = $t[7]; 
	my $ctg2PosDist = $t[8];
	
	##filter contig links that not locus in either head or tail
	next if($ctg1PosDist > $DistToEnd_cutoff || $ctg2PosDist > $DistToEnd_cutoff);

	next if(! exists $UsedContigs{$ctg1} || ! exists $UsedContigs{$ctg2} );
	
	push @Contacts, \@t;
	
}
close IN;

#print Dumper \%ReciprocalMax;
#exit;

@Contacts = sort {$b->[2] <=> $a->[2]} @Contacts;

##output the sorted lines
print "#CtgId1\tCtgId2\tMaxContact\tCtg1Pos\tCtg2Pos\tCtg1PosRate\tCtg2PosRate\tDist1ToEnd\tDist2ToEnd\tCtgId1\tCtg1BinRange\tCtg1Bin\tCtgId2\tCtg2BinRange\tCtg2Bin\n";
for (my $i = 0; $i < @Contacts; $i++) {
	my $p = $Contacts[$i];
	my $line = join("\t", @$p);
	print  "$line\n";
}

