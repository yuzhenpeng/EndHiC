gzip -d Atha.contigs.fa.gz

perl ../fastaDeal.pl -attr id:len Atha.contigs.fa > Atha.contigs.fa.len 

perl ../endhic.pl Atha.contigs.fa.len AthaHiC_100000_abs.bed AthaHiC_100000.matrix AthaHiC_100000_iced.matrix

perl ../cluster2agp.pl 04.summary_and_merging_results/z.EndHiC.A.results.summary.cluster Atha.contigs.fa.len > Atha.scaffolds.agp

perl ../agp2fasta.pl Atha.scaffolds.agp Atha.contigs.fa > Atha.scaffolds.fa


