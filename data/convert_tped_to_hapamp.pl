#!/usr/bin/env perl


=head1 [progam_name]

 description:
   - converts tped files to hapmap files.


=head2 usage

  # convert tped to HapMap
  perl /soft_bio/PMG/perl/convert_tped_to_hapmap.pl --tped hapmap3_r2_b36_fwd.consensus.qc.poly--100_inds.tped --tfam hapmap3_r2_b36_fwd.consensus.qc.poly--100_inds.tfam --build=ncbi_36

 # See documentation
 perldoc convert_tped_to_hapmap.pl


=head2 comments

Pedigree files used by plink (.ped) are individual oriented (individuals in rows) but HapMap are SNP oriented (SNPs in rows). For converting from any SNP oriented format from or to plink, the best approach is to use tped (transposed ped) and then use plink to transpose to/from ped.


For converting from ped to tped:

  - Download 100 individuals from hapampIII in ped format
  wget -qO- ftp://ftp.ncbi.nlm.nih.gov/hapmap/genotypes/2009-01_phaseIII/plink_format/hapmap3_r2_b36_fwd.consensus.qc.poly.ped.bz2 | bunzip2 -c | head -n 100 > hapmap3_r2_b36_fwd.consensus.qc.poly--100_inds.ped

  - Download the map file
  wget -qO- ftp://ftp.ncbi.nlm.nih.gov/hapmap/genotypes/2009-01_phaseIII/plink_format/hapmap3_r2_b36_fwd.consensus.qc.poly.map.bz2 |  bunzip2 -c > hapmap3_r2_b36_fwd.consensus.qc.poly--100_inds.map

  # the .map has the '--100_inds' flag only to have the same base name that the .ped file.


  - convert to tped
   plink --noweb --file hapmap3_r2_b36_fwd.consensus.qc.poly--100_inds --recode --transpose --out hapmap3_r2_b36_fwd.consensus.qc.poly--100_inds

  - convert tped to hapmap
  perl /soft_bio/PMG/perl/convert_tped_to_hapmap.pl --tped hapmap3_r2_b36_fwd.consensus.qc.poly--100_inds.tped --tfam hapmap3_r2_b36_fwd.consensus.qc.poly--100_inds.tfam --build=ncbi_36


=head2 file type description

  tped files:

     - 4 columns (like map)
     - 5th until end => genotypes (two columns per ind). unknown = 0 or N

  tfam file

      Family ID
      Individual ID
      Paternal ID
      Maternal ID
      Sex (1=male; 2=female; other=unknown)
      Phenotype


  map
   - 4 columns
     - chr
     - snp_name
     - cM
     - chr_pos


 hapmap_files

        -HapMap file format:
        The current release consists of text-table files only, with the following columns:

        Col1: refSNP rs# identifier at the time of release (NB: it might merge
          with another rs# in the future)
        Col2: SNP alleles according to dbSNP
        Col3: chromosome that SNP maps to
        Col4: chromosome position of SNP, in basepairs on reference sequence
        Col5: strand of reference sequence that SNP maps to
        Col6: version of reference sequence assembly (currently NCBI build36)
        Col7: HapMap genotyping center that produced the genotypes
        Col8: LSID for HapMap protocol used for genotyping
        Col9: LSID for HapMap assay used for genotyping
        Col10: LSID for panel of individuals genotyped
        Col11: QC-code, currently 'QC+' for all entries (for future use)
        Col12 and on: observed genotypes of samples, one per column, sample
             identifiers in column headers (Coriell catalog numbers, example:
              NA10847).



=cut

#use feature ':5.10';
use strict;
#use warnings;
#use Data::Dumper;

use Getopt::Long;

my $prog = $0;
my $usage = <<EOQ;
Usage for $0:

  >$prog [-test -help -verbose] --tped xx  --tfam yy --hapmap zz --build=ncbi_36 


  optional
  --------

  --panel=ncbi_36
  --strand_all_snps=+

EOQ

my $help;
my $test;
my $debug;
my $verbose =1;

my $bsub;
my $log;
my $stdout;

my $file_tped;
my $file_tfam;
my $file_hapmap;
my $file_pheno;
my $file_map;
my $build;
my $strand_all_snps;
my $panel;

my $ok = GetOptions(
                    'test'              => \$test,
                    'debug:i'           => \$debug,
                    'verbose:i'         => \$verbose,
                    'h|help'            => \$help,
                    'log'               => \$log,
                    'bsub'              => \$bsub,
                    'stdout'            => \$stdout,
                    'tped=s'            => \$file_tped,
                    'tfam=s'            => \$file_tfam,
                    'hapmap=s'          => \$file_hapmap,
                    'pheno=s'           => \$file_pheno,
                    'map=s'             => \$file_map,
                    'strand_all_snps=s' => \$strand_all_snps,
                    'build=s'           => \$build,
                    'panel=s'           => \$panel,
                   );

if ($help || !$ok ) {
    print $usage;
    exit;
}

unless ($build) {
    print "#[ERROR] Sorry but you need to document your hapmap genotypes with a genome build\n";

    print $usage;
    exit;
}

if (! $file_tped || ! $file_tfam ) {
    print "#[ERROR] Sorry but you need a tped and tfam file\n";

    print $usage;
    exit;
}

$file_hapmap ||=  $file_tped.'.hapmap';
my $log_file  = $file_hapmap.'.log';

# variable to store the log
my $log_str;

start_log("conversion ped to hapmap");

main();

end_log();

sub main {

    # read each column from tped and convert to hapmap

    $DB::single=1;
    feedback_log("#[MSG] loading tfam file '$file_tfam'\n");
    my $tfam = load_tfam($file_tfam);

    $DB::single=1;
    open (my $tped_fh,   '<', $file_tped)   or die "Sorry unable to open tped file '$file_tped' for reading:$!\n";
    open (my $hapmap_fh, '>', $file_hapmap) or die "Sorry unable to open hapmap file '$file_hapmap' for writing:$!\n";


    # print the header of hapmap
    $DB::single=1;
    # expect ind ids to be unique, if you don't whant the id  merged with family id
    # just in case I am joining FID__IID iwth double underscore so it can be easily splitted
    my $inds = [map {$_->[0].'__'.$_->[1]} @$tfam];  # <TODO> CHECK
    print {$hapmap_fh} join("\t",qw(rs# alleles chrom pos strand assembly# center protLSID assayLSID panelLSID QCcode), @$inds),"\n";


    feedback_log("#[MSG] processing tped file '$file_tped'.\n");
    while (my $line=<$tped_fh>) {
        chomp $line;

        # print a '.' every 500 SNPs
        print {*STDERR} '.' unless ($. % 500);

        my @items = split /\s+/, $line;
        my $dat= {
                  '01_name'        => $items[1],
                  '02_alleles'     => get_alleles(\@items),
                  '03_chr'         => $items[0],
                  '04_pos'         => $items[3],
                  '05_strand'      => $strand_all_snps?  $strand_all_snps : '.',
                  '06_build'       => $build,
                  '07_geno_center' => '-',
                  '08_protocol'    => '-',
                  '09_assay'       => '-',
                  '10_panel'       => $panel? $panel:'-',
                  '11_qc_code'     => 'QC+',
                  '12_geno_str'    => get_geno_string(\@items, $inds),
                 };
        $DB::single=1;
        print {$hapmap_fh} join ("\t" , map{$dat->{$_}} sort keys %$dat). "\n";

    }


}



=head2 get_geno_string

 Title   : get_geno_string
 Usage   :
 Function:
 Example :
 Returns :
 Args    :


=cut

sub get_geno_string{
    my ($items, $inds) = @_;

    $DB::single=1;
    my @genos =  @$items[4..(@$items-1)];
    if (@genos % 2 ) {
        # more columns that expected
        die "#[ERROR] columns not multiplo of 2 in parsed ped file ' $file_tped' at line $.";
    }
    if (@genos/2 != @$inds) {
        # error more geno than inds
        die "#[ERROR]  different number of individuals and genotypes in parsed ped file ' $file_tped' at line $.: genos=".(@genos/2)." inds=".@$inds."\n";
    }
    
    return join ("\t", map {
                             my $idx=$_*2;
                             $genos[$idx+0].$genos[$idx+1]
                         } 0..((@genos/2)-1)
                 )
}


=head2 get_alleles

 Title   : get_alleles
 Usage   :
 Function:
 Example :
 Returns :
 Args    :


=cut

sub get_alleles{
    my ($items) = @_;
    my %h; 
    map{$h{$_}++} @$items[4..(@$items-1)];
    return join('/',sort keys %h);
}


=head2 write_log

 Title   : write_log
 Usage   :
 Function:
 Example :
 Returns :
 Args    : $log_str   str with the message to log


=cut

sub write_log{
    my ($log_str) = @_;

    write_file($log_file, $log_str);

}


=head2 feedback_log

 Title   : feedback_log
 Usage   :
 Function:  print to stderr and add tothe log_str the message. (The str should contain the \n if needed)
 Example :
 Returns :
 Args    : $str = string


=cut

sub feedback_log{
    my ($str) = @_;

    print {*STDERR} $str;

    $log_str .= $str;
}


=head2 start_log

 Title   : start_log
 Usage   :
 Function: start log file with the name of the files
 Example :
 Returns :
 Args    : an extra message to add to the log starting


=cut

sub start_log{
    my ($title, $extra_msg) = @_;

    my $date = localtime;


    $title ||= "$0";
    my $out = "== LOG $title ==\n";
    $out .= 'Started at: ' . $date . "\n";
    $out .= "  hapmap file   : " . $file_hapmap . "\n";
    $out .= "  tped file  : " . $file_tped . "\n";
    $out .= "  tfam file  : " . $file_tfam . "\n";
    $out .= "  map file   : " . $file_map . "\n";
    $out .= "  pheno file : " . $file_pheno . "\n";
    $out .= "\n";
    $out .= $extra_msg;

    feedback_log($out);

}

=head2 end_log

 Title   : end_log
 Usage   :
 Function:
 Example :
 Returns :
 Args    :


=cut

sub end_log{
    my ($extra_msg) = @_;

    my $date = localtime;

    my $out = 'ENDED at: ' . $date . "\n";
    $out .= $extra_msg;
    $out .= "== END ==\n";
    feedback_log($out);
}



=head2 load_pheno_file

 Title   : load_pheno_file
 Usage   :
 Function:
 Example :
 Returns : a hash with the IID as key and values. The two first columns should be FID and IID and the third is 'sex'
 Args    :


=cut

sub load_pheno_file{
    my ($file) = @_;

    my $pheno_hash = read_table_to_hash($file);

    return $pheno_hash;

}


=head2 load_tfam

 Title   : load_tfam
 Usage   :
 Function:
 Example :
 Returns :
 Args    :


=cut

sub load_tfam{
    my ($file_tfam) = @_;

    my $rows = read_table($file_tfam, 0);


    return $rows;

}


=head2 read_table

 Title   : read_table
 Usage   :
 Function: parse files separated with tabs and bare columns (no quotes nor tabs to scape)
 Example :
 Returns :
 Args    : $file
           $has_header


  <TO_DO> think if we want to capture headers and return them??

=cut

sub read_table{
    my ($file, $has_header) = @_;

    die "#[ERROR] no argument passed to sub read_table\n" unless $file;
    unless (-e $file) {
        die "#[ERROR] Sorry but the file '$file' does not exist.\n";
    }

    open (my $filefh, '<',$file) or die "#[ERROR] unable to open file '$file' for reading:$!\n";


    my $count;
    my @rows;
    while( my $line=<$filefh>) {

        next if $.==1 && $has_header;

        chomp $line;
        $count ++;

        my @items = split /\s+/, $line;
        push @rows, [@items];

    }
    feedback_log( "...end. $count lines processed\n");

    return \@rows;
}

=head2 read_table_to_hash

 Title   : read_table_to_hash
 Usage   :
 Function: creates a hash of hashes. A hash with keys the first column
     and values being another hash constructed with all columns ad keys
     taken from the header
 Example :
 Returns :
 Args    :


=cut

sub read_table_to_hash{
    my ($file) = @_;

    # a header is mandatory

    die "#[ERROR] no argument passed to sub read_table\n" unless $file;
    unless (-e $file) {
        die "#[ERROR] Sorry but the file '$file' does not exist.\n";
    }

    open (my $filefh, '<',$file) or die "unable to open $file_map for reading:$!\n";

    my @headers;
    my $count;
    my %hash;
    my $hc;
    while (my $line=<$filefh>) {

        chomp $line;
        $count ++;

        my @items = split "\t", $line;

        if ($.==1){
            @headers = @items;
            $hc = @headers;
        }
        else {
            my $rc = @items;
            die "#[ERROR] Sorry but line '$.' has wrong number of columns. header=$hc, this_row=$rc\n" unless $hc==$rc;
            @{$hash{$items[0]}}{map{lc}@headers}=@items;
        }
    }
    feedback_log( ".. $count lines processed for $file\n");

    return \%hash;
}



=head2 final_qc

 Title   : final_qc
 Usage   :
 Function:
 Example :
 Returns :
 Args    :


=cut

sub final_qc{
    my ($ind_ids,  $pheno_hash,  $map_hash) = @_;


}
