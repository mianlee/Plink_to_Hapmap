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

Then, you will get ```GenoT.tped.hapmap``` file.


# Installing SNPhylo on Linux (Ubuntu 16.06)

The installation of SNPhylo on my Ubuntu 16.06 is a little bit different from the manual, but it worked for me. If you encounter the same situation, please follow my steps.


1. Install the R (if R is not installed; as root)

```
apt-get -y install r-base-dev r-cran-getopt r-cran-rgl
```

My R version: 3.6.1 (2019-07-05)

2. Make a SNPhylo directory in your home directory

```
echo ${HOME}
/home/mianlee


SNPHYLO_HOME="/home/mianlee/snphylo"

mkdir -p "${SNPHYLO_HOME}/bin"

```


3. Install the MUSCLE (if MUSCLE is not installed)

```
curl -O http://www.drive5.com/muscle/downloads3.8.31/muscle3.8.31_i86linux64.tar.gz


tar xvfz muscle3.8.31_i86linux64.tar.gz -C "${SNPHYLO_HOME}/bin"


ln -sf "${SNPHYLO_HOME}/bin/muscle3.8.31_i86linux64" "${SNPHYLO_HOME}/bin/muscle"
```

4. Install the Phylip package (if Phylip package is not installed)


I downloaded [phylip-3.697](http://evolution.genetics.washington.edu/phylip/getme-new1.html)

```

tar xvfz phylip-3.697.tar.gz -C "${SNPHYLO_HOME}"


ln -sf "${SNPHYLO_HOME}/phylip-3.697" "${SNPHYLO_HOME}/phylip"

pushd "${SNPHYLO_HOME}/phylip/src"

cp Makefile.unx Makefile
make install


popd

```


5.Intall R packages: ```gdsfmt```, ```SNPRelate```, ```getopt```,```igraph``` and ```phangorn```.

```
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("gdsfmt")

BiocManager::install("SNPRelate")


install.packages("getopt")

```

```
# Install libgfortran.so.4 on ubuntu 16.06
sudo add-apt-repository ppa:jonathonf/gcc-7.1
sudo apt-get update

sudo apt-get install gcc-7 g++-7
sudo apt-get install gfortran-7

install.packages("igraph")
install.packages("phangorn")

```

6. Install the SNPhylo

```
curl -O http://chibba.pgml.uga.edu/snphylo/snphylo.tar.gz


tar xvfz snphylo.tar.gz -C "${SNPHYLO_HOME}"
```

7. Setup the SNPhylo

```
$ pushd "${SNPHYLO_HOME}/SNPhylo"

$ bash setup.sh

START TO SET UP FOR SNPHYLO!!!

The detected path of Rscript is /bin/Rscript. Is it correct? [Y/n] y

The detected path of python is /bin/python. Is it correct? [Y/n] y

muscle is not found. Is the program already installed? [y/N] y
Please enter the path of muscle program (ex: /home/foo/bin/muscle): /home/foo/snphylo/bin/muscle

dnaml is not found. Is the program already installed? [y/N] y
Please enter the path of dnaml program (ex: /home/foo/bin/dnaml): /home/foo/snphylo/phylip/exe/dnaml

At least one R package (gdsfmt, SNPRelate, getopt or phangorn) to run this pipeline is not found. Are the packages already installed? [y/N]

Do you want to install the packages by this script? [y/N] y

...... (Installing R packages)

SNPHYLO is successfully installed!!!

$ popd

```

For other operating system, see SNPhylo [homepage](http://chibba.pgml.uga.edu/snphylo/).



## Run SNPhylo

SNPhylo doesn't work with python3, so I use python2 instead of python3 to set up "bash setup.sh" again.

```
./snphylo.sh -H ~/Desktop/NatGeo/GenoT.tped.hapmap
```



