# Covert Plink format to Hapmap format

Reasons:

I want ot use snp microarray data to built a phylogenetic tree. I did some google search, and found out ```[SNPhylo](http://chibba.pgml.uga.edu/snphylo/)``` can achieve this goal. But it requires Hapmap file format.

What I have are [```Geno.bed```](data/Geno.bed), [```Geno.bim```](data/Geno.bim) and [```Geno.fam```](data/Geno.fam), the binary Plink format. if you have ```Geno.ped``` and ```Geno.map``` files, it will work the same way.

The solution is proposed by **Pablo Marin-Garcia** from the [Biostar Forum Question](https://www.biostars.org/p/18322/).


For converting ped to HapMap I convert first to tped with plink, and I used plink1.9:

```
plink  --bfile Geno --recode transpose --out GenoT


PLINK v1.90b4 64-bit (20 Mar 2017)             www.cog-genomics.org/plink/1.9/
(C) 2005-2017 Shaun Purcell, Christopher Chang   GNU General Public License v3
Logging to GenoT.log.
Options in effect:
  --bfile Geno
  --out GenoT
  --recode transpose

8703 MB RAM detected; reserving 4351 MB for main workspace.
301746 variants loaded from .bim file.
42 people (40 males, 2 females) loaded from .fam.
Using 1 thread (no multithreaded calculations invoked).
Before main variant filters, 42 founders and 0 nonfounders present.
Calculating allele frequencies... done.
Total genotyping rate is 0.987983.
301746 variants and 42 people pass filters and QC.
Note: No phenotypes present.
--recode transpose to GenoT.tped + GenoT.tfam ... done.

```


And then his perl script [convert_tped_to_hapmap.pl](data/convert_tped_to_hapamp.pl).

```
 perl convert_tped_to_hapamp.pl --tped GenoT.tped --tfam GenoT.tfam --build=ncbi_36
 
 
 
 
 == LOG conversion ped to hapmap ==
Started at: Mon Aug 19 11:30:43 2019
  hapmap file   : GenoT.tped.hapmap
  tped file  : GenoT.tped
  tfam file  : GenoT.tfam
  map file   : 
  pheno file : 

#[MSG] loading tfam file 'GenoT.tfam'
...end. 42 lines processed
#[MSG] processing tped file 'GenoT.tped'.
...........................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................ENDED at: Mon Aug 19 11:31:19 2019
== END ==

 ```



