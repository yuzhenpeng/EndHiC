#!/usr/bin/perl

=head1 Name

normalize_ctgContact_distance.pl  -- normalize the contacts and calculate the distance between contigs

=head1 Description

Using the halfContig contact file as input, which is generated by
"ctgContact_from_ctgEndContacts.pl" with option --binnum -1";

=head1 Version

  Author: Fan Wei, fanwei@caas.cn
  Version: 1.0,  Date: 2021/7/6
  Note:

=head1 Usage
  normalize_ctgContact_distance.pl   <halfContig_ctgContact_file>
  --binnum <int>  number of bins included in contig head or contig tail, cutoff to filter short contigs, default=1
  --normalize     only normalize the contig contact values, but not convert to 0-1 distance
  --verbose   output running progress information to screen  
  --help      output help information to screen  

=head1 Exmple

  perl ../normalize_ctgContact_distance.pl  humanHiC_100000.matrix.halfContig.ctgContact > humanHiC_100000.matrix.halfContig.ctgContact.normalize.distance
  perl ../normalize_ctgContact_distance.pl  --normalize humanHiC_100000.matrix.halfContig.ctgContact > humanHiC_100000.matrix.halfContig.ctgContact.normalize
  

=cut

use strict;
use Getopt::Long;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname); 
use Data::Dumper;


##get options from command line into variables and set default values
my $HicPro_BinNum;
my $Normalize;
my ($Verbose,$Help);
GetOptions(
	"binnum:i"=>\$HicPro_BinNum,
	"normalize"=>\$Normalize,
	"verbose"=>\$Verbose,
	"help"=>\$Help
);
$HicPro_BinNum ||= 1;
die `pod2text $0` if (@ARGV == 0 || $Help);

my $ctgContact_file = shift;


my %Data;
my @MaxNormal;
#my @AvgNormal;

##ptg000026l      ptg000080l      26.00   head    head    161     12
open IN, $ctgContact_file || die "fail $ctgContact_file";
while (<IN>) {
	next if(/^\#/);
	my ($ctg1, $ctg2, $contact, $ctg1pos, $ctg2pos, $binnum1, $binnum2) = split /\s+/;
	next if($binnum1 < $HicPro_BinNum || $binnum2 < $HicPro_BinNum);
	
	push @{$Data{$ctg1}{$ctg2}},  [$contact, $ctg1pos, $ctg2pos, $binnum1, $binnum2];


}
close IN;

#print Dumper \%Data;

foreach my $ctg1 (sort keys %Data) {
	my $ctg1_p = $Data{$ctg1};
	foreach my $ctg2 (sort keys %$ctg1_p) {
		my $ctg2_p = $ctg1_p->{$ctg2};
		
		my $max_contact = 0;
		my $max_contact_binbin = 0;
		my $total_contact = 0;
		my $total_contact_binbin = 0;
		my $max_ctg1pos;
		my $max_ctg2pos;
		
		##head vs head, head vs tail, tail vs head, tail vs tail
		foreach my $p (@$ctg2_p) {
			my ($contact, $ctg1pos, $ctg2pos, $binnum1, $binnum2) = @$p;
			#print "$contact, $ctg1pos, $ctg2pos, $binnum1, $binnum2\n";
			$total_contact += $contact;
			$total_contact_binbin += $binnum1 * $binnum2;
			if ($max_contact < $contact) {
				$max_contact = $contact;
				$max_contact_binbin = $binnum1 * $binnum2;
				$max_ctg1pos = $ctg1pos;
				$max_ctg2pos = $ctg2pos;
			}
		}

		my $max_contact_normal = $max_contact / $max_contact_binbin;
		#my $average_contact_normal = $total_contact / $total_contact_binbin;

		push @MaxNormal, [$ctg1,$ctg2,$max_contact_normal, $max_contact, $max_ctg1pos, $max_ctg2pos];
		#push @AvgNormal, [$ctg1,$ctg2,$average_contact_normal];
	
	}
}




my $max_value = 0;
foreach my $p (@MaxNormal) {
	if($max_value < $p->[2]){
		$max_value = $p->[2];
	}
}

##only output the max contact for each contig pairs, the head or tail postion is kept

if (defined $Normalize) {
	print  "#ctg1\tctg2\tcontact_normalized\tcontact\tctg1pos\tctg2pos\n";
}else{
	print  "#ctg1\tctg2\tdistance[0-1]\tcontact_normalized_scaled\tcontact_normalized\tcontact\tctg1pos\tctg2pos\n";
}

@MaxNormal = sort {$b->[2] <=> $a->[2]} @MaxNormal;
foreach my $p (@MaxNormal) {
	my ($ctg1,$ctg2,$max_contact_normal, $max_contact, $max_ctg1pos, $max_ctg2pos) = @$p;
	my $max_contact_normal_scaled = $max_contact_normal / $max_value;
	my $distance = 1 - $max_contact_normal_scaled;
	
	if (defined $Normalize) {
		print  "$ctg1\t$ctg2\t$max_contact_normal\t$max_contact\t$max_ctg1pos\t$max_ctg2pos\n";
	}else{
		print  "$ctg1\t$ctg2\t$distance\t$max_contact_normal_scaled\t$max_contact_normal\t$max_contact\t$max_ctg1pos\t$max_ctg2pos\n";
	}
}



#my $max_value = 0;
#foreach my $p (@AvgNormal) {
#	if($max_value < $p->[2]){
#		$max_value = $p->[2];
#	}
#}
#
#print  "#ctg1\tctg2\taverage_contact_normal\n";
#print STDERR "#ctg1\tctg2\tdistance[0-1]\taverage_contact_normal_scaled[max:1]\taverage_contact_normal\n";
#
#foreach my $p (@AvgNormal) {
#	my ($ctg1,$ctg2,$average_contact_normal) = @$p;
#	my $average_contact_normal_scaled = $average_contact_normal / $max_value;
#	my $distance = 1 - $average_contact_normal_scaled;
#	print "$ctg1\t$ctg2\t$average_contact_normal\n";
#	print STDERR "$ctg1\t$ctg2\t$distance\t$average_contact_normal_scaled\t$average_contact_normal\n";
#}

