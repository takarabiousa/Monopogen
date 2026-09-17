# Monopogen

> **This is a fork.** This repository (`takarabiousa/Monopogen`) is a fork of
> [`KChen-lab/Monopogen`](https://github.com/KChen-lab/Monopogen), maintained by
> Takara Bio USA. The `v1.0` branch is based on the upstream
> [`v1.0.0`](https://github.com/KChen-lab/Monopogen/releases/tag/v1.0.0) release
> tag. See [Changes made in this fork](#changes-made-in-this-fork) below for
> what differs from upstream, and [License](#license) for licensing and
> attribution.

SNV calling from single cell sequencing data

<image src="./example/Fig1.png" width="400"> 

**Monopogen** is an analysis package for SNV calling from single-cell sequencing, developed and maintained by [Ken chen's lab](https://sites.google.com/view/kchenlab/Home) in MDACC. `Monopogen` works on sequencing datasets generated from single cell RNA 10x 5', 10x 3', smartseq, single ATAC-seq technoloiges, scDNA-seq etc. 
It is composed of three modules: 
* **Data preprocess**. This module removes reads with high alignment mismatches from single cell sequencing and also makes data formats compatiable with Monopongen.
* **Germline SNV calling**. Given the sparsity of single cell sequencing data, we leverage linkage disequilibrium (LD) from external reference panel(such as 1KG3, TopMed) to improve both SNV calling accuracy and detection sensitivity. 
* **Putative somatic SNV calling**. We extended the machinery of LD refinement from human population level to cell population level. We statistically phased the observed alleles with adjacent germline alleles to estimate the degree of LD, taking into consideration widespread sparseness and allelic dropout in single-cell sequencing data, and calculated a probabilistic score as an indicator of somatic SNVs.  The putative somatic SNVs were further genotyped at cell type/cluster level from `Monovar` developed in [Ken chen's lab](https://github.com/KChen-lab/MonoVar).

The output of `Monopogen` will enable 1) ancestry identificaiton on single cell samples; 2) genome-wide association study on the celluar level if sample size is sufficient, and 3) putative somatic SNV investigation.


## 1. Dependencies

All runtime dependencies -- both the Python packages and the external tools
(`samtools`, `bcftools`, `tabix`, `beagle`, `openjdk`) -- are pinned in
[`environment.yml`](./environment.yml) and resolved from a conda environment.
Tools are looked up on `PATH`; there is no bundled-binary directory to manage.

## 2. Installation

`git clone https://github.com/takarabiousa/Monopogen.git`
`cd Monopogen`
`git checkout v1.0`
`conda env create -f environment.yml`
`conda activate monopogen`
`pip install -e .`

## 3. Usage of Monopogen
  
## 3.1 Data preprocess

You can type the following command to get the help information.

`python ./src/Monopogen.py  preProcess --help`

```
usage: Monopogen.py preProcess [-h] -b BAMFILE [-o OUT]
                               [-m MAX_MISMATCH] [-t NTHREADS]

optional arguments:
  -h, --help            show this help message and exit
  -b BAMFILE, --bamFile BAMFILE
                        The bam file for the study sample, the bam file should
                        be sorted. If there are multiple samples, each row
                        with each sample (default: None)
  -o OUT, --out OUT     The output director (default: None)
  -m MAX_MISMATCH, --max-mismatch MAX_MISMATCH
                        The maximal alignment mismatch allowed in one reads
                        for variant calling (default: 3)
  -t NTHREADS, --nthreads NTHREADS
                        Number of threads used for SNVs calling (default: 1)
 ```

We provide one example dataset provided the `example/` folder, which includes:
* `A.bam (.bai)`  
  The bam file storing read alignment for sample A.
* `B.bam (.bai)`  
  The bam file storing read alignment for sample B. 
* `CCDG_14151_B01_GRM_WGS_2020-08-05_chr20.filtered.shapeit2-duohmm-phased.vcf.gz`  
  The reference panel with over 3,000 samples in 1000 Genome database. Only SNVs located in chr20: 0-2Mb were extracted in this vcf file. 
* `chr20_2Mb.hg38.fa (.fai)`  
  The genome reference used for read aligments. Only seuqences in chr20:0-20Mb were extracted in this fasta file.

There is a bash script `./test/runPreprocess.sh` to run above example in the folder `test`. You need to prepare the bam file list for option `-b`. If you have multiple sample in this file, you can use more CPUs by setting `-t` to make `Monopogen` faster.  Run the test script as following:
  
```
path="XXy/Monopogen"

python  ${path}/src/Monopogen.py  preProcess -b bam.lst -o out -t 8

```
After running the `preProcess` module, there will be bam files after quality controls in the folder `out/Bam/` which will be used for downstream SNV calling.
  
## 3.2 Germline SNV calling  
 
You can type the following command to get the help information.

`python ./src/Monopogen.py  germline --help`

```
usage: Monopogen.py germline [-h] -r REGION -s
                             {varScan,varImpute,varPhasing,all} [-o OUT] -g
                             REFERENCE -p IMPUTATION_PANEL
                             [-m MAX_SOFTCLIPPED] [-t NTHREADS]

optional arguments:
  -h, --help            show this help message and exit
  -r REGION, --region REGION
                        The genome regions for variant calling (default: None)
  -s {varScan,varImpute,varPhasing,all}, --step {varScan,varImpute,varPhasing,all}
                        Run germline variant calling step by step (default:
                        all)
  -o OUT, --out OUT     The output director (default: None)
  -g REFERENCE, --reference REFERENCE
                        The human genome reference used for alignment
                        (default: None)
  -p IMPUTATION_PANEL, --imputation-panel IMPUTATION_PANEL
                        The population-level variant panel for variant
                        imputation refinement, such as 1000 Genome 3 (default:
                        None)
  -t NTHREADS, --nthreads NTHREADS
                        Number of threads used for SNVs calling (default: 1)
 ```

There is a bash script `./test/runGermline.sh` to run above example. You need to prepare the genome region file list for option `-r` with an example shown in `test/region.lst`. Each region is in one row. If you want to call the whole chromosome, you can only specficy the chromosome ID in each row.  Also you can use more CPUs by setting `-t` to make `Monopogen` faster when there are many genome regions.  Run the test script as following:
  
```
python  ${path}/src/Monopogen.py  germline  \
    -t 8   -r  region.lst \
    -p  ../example/CCDG_14151_B01_GRM_WGS_2020-08-05_chr20.filtered.shapeit2-duohmm-phased.vcf.gz  \
    -g  ../example/chr20_2Mb.hg38.fa   -s all  -o out

```
The `germline` module will generate the phased VCF files with name `*.phased.vcf.gz` in the folder `out/germline`. If there are multiple samples in the bam file list from `-b` option in `preProcess` module, the phased VCF files will contain genotypes from multiple samples. The output of phased genotypes are as following:
  
```
##fileformat=VCFv4.2
##filedate=20230422
##source="beagle.27Jul16.86a.jar (version 4.1)"
##INFO=<ID=AF,Number=A,Type=Float,Description="Estimated ALT Allele Frequencies">
##INFO=<ID=AR2,Number=1,Type=Float,Description="Allelic R-Squared: estimated squared correlation betwe
##INFO=<ID=DR2,Number=1,Type=Float,Description="Dosage R-Squared: estimated squared correlation betwee
##INFO=<ID=IMP,Number=0,Type=Flag,Description="Imputed marker">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=DS,Number=A,Type=Float,Description="estimated ALT dose [P(RA) + P(AA)]">
##FORMAT=<ID=GP,Number=G,Type=Float,Description="Estimated Genotype Probability">
#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT  19D013_European_F_78    19D014_European_M_84
chr20   68303   .       T       C       .       PASS    .       GT      1|0     1|1
chr20   88108   .       T       C       .       PASS    .       GT      1|1     0|1
chr20   127687  .       A       C       .       PASS    .       GT      1|1     1|1
chr20   153835  .       T       C       .       PASS    .       GT      1|0     1|1
chr20   154002  .       C       T       .       PASS    .       GT      1|1     1|1
chr20   159104  .       T       C       .       PASS    .       GT      1|1     1|1
chr20   167839  .       T       C       .       PASS    .       GT      1|1     1|1
chr20   198814  .       A       T       .       PASS    .       GT      1|0     1|1
chr20   231710  .       T       G       .       PASS    .       GT      1|1     1|1
chr20   237210  .       T       C       .       PASS    .       GT      1|1     1|1
chr20   247326  .       G       A       .       PASS    .       GT      1|1     1|0
chr20   248854  .       T       C       .       PASS    .       GT      1|1     1|0
chr20   255081  .       G       A       .       PASS    .       GT      1|1     1|0
chr20   274893  .       G       C       .       PASS    .       GT      0|1     1|1
chr20   275122  .       G       T       .       PASS    .       GT      0|1     1|1
chr20   275241  .       G       A       .       PASS    .       GT      0|1     1|0
chr20   275361  .       C       T       .       PASS    .       GT      0|1     1|0
chr20   275932  .       A       G       .       PASS    .       GT      0|1     1|0
chr20   276086  .       T       A       .       PASS    .       GT      0|1     1|0

```
  
 
## Run on multiple chromosomes and multiple samples 

Users can submit jobs with multiple chromosomes in the parallele fashion as following:

```
path="XX/Monopogen"

for chr in {1..22}
do 
  python  ../src/Monopogen.py    germline  \
        -b  ../example/chr${chr}_2Mb.rh.filter.sort.bam  \
        -y  single  \
        -t  all  \
        -c  chr${chr}  \
        -o  out \
        -d  10 \
        -p  ../example/CCDG_14151_B01_GRM_WGS_2020-08-05_chr${chr}.filtered.shapeit2-duohmm-phased.vcf.gz  \
        -r  ../example/chr${chr}_2Mb.hg38.fa   -m 3 -s 5
done

```



## 7. FAQs 
* ***where to download 1KG3 reference panel (hg38)***
  http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000G_2504_high_coverage/working/20201028_3202_phased/
  
* ***how to perform downstream PCA-based projection or admixture analysis***  
  PCA-based projection analysis can be peformed using [LASER 2.0](http://csg.sph.umich.edu/chaolong/LASER/)
   
* ***AssertionError: Program samtools/bcftools/bgzip/beagle cannot be found on PATH!***  
  This fork resolves every external tool from the active conda environment
  rather than a bundled `apps` folder -- make sure you've run
  `conda env create -f environment.yml && conda activate monopogen` before
  invoking `Monopogen.py`.

  
## 8. Citation
[Dou J, Tan Y, Wang J, Cheng X, Han KY, Hon CC, Park WY, Shin JW, Chen H, Prabhakar S, Navin N, Chen K. Monopogen : single nucleotide variant calling from single cell sequencing. bioRxiv. 2022 Jan 1](https://www.biorxiv.org/content/10.1101/2022.12.04.519058v1.abstract)

## Changes made in this fork

The `v1.0` branch starts from upstream's [`v1.0.0`](https://github.com/KChen-lab/Monopogen/releases/tag/v1.0.0)
release tag. Changes on top of that tag:

* **Added [`environment.yml`](./environment.yml)**, pinning every external
  tool (`samtools`, `bcftools`, `tabix`, `beagle`) and Python dependency
  (`pysam`, `numpy`, `pandas`, `scipy`) to versions already validated against
  this codebase in downstream production use, rather than latest releases.
  Notably `beagle` is pinned to a 4.1 build (`4.1_21Jan17.6cc.jar`): the code
  hardcodes `beagle.27Jul16.86a.jar` and passes `modelscale=`/`niterations=`/
  `impute=`/`gprobs=`, all Beagle 4.x-only parameters that Beagle 5.x's
  rewritten phasing algorithm no longer accepts.
* **Removed the required `--app-path`/`-a` argument** (and the bundled
  `apps/`-relative binary-path convention it implied) from `preProcess`,
  `germline`, and `somatic`. Tools are now resolved on `PATH`, provided by
  the conda environment above -- consistent with how `hzvcf.py` already
  invoked `tabix` elsewhere in this codebase.
* **Fixed two crash bugs uncovered by that removal**: `BamSplit()` referenced
  `args.samtools`, and `bam2mat()` referenced `args.bcftools`/`args.java` --
  none of which were ever defined by `argparse`, so both would raise
  `AttributeError` on the `somatic` command path. They now use the same
  PATH-resolved tool names as everywhere else.
* **Removed `pillow`** from the dependency list: listed in upstream's
  `requirements.txt` but not actually imported anywhere in the codebase.

**Known, deliberately untouched**: `bam2mat()` still hardcodes its reference
genome, genetic map, and imputation panel paths to the original author's
institutional scratch space (e.g. `/rsrch3/scratch/bcb/jdou1/...`). This
predates this fork and is unrelated to the changes above; it's flagged with a
comment in `src/Monopogen.py` rather than fixed here.

## License

Monopogen's licensing is inconsistent upstream: the repository-level
[`LICENSE`](./LICENSE) file (added upstream after this fork's `v1.0.0` base,
carried forward here) states GPL-3.0, which is also what GitHub's own license
detection reports for [`KChen-lab/Monopogen`](https://github.com/KChen-lab/Monopogen).
However, several individual source files (e.g. `alleles_prior.py`,
`base_q_ascii.py`) carry earlier MIT-style permission notices with a
`Copyright (c) 2015` line, and `setup.py` itself declares an MIT classifier --
both apparently inherited from an ancestor tool. This fork does not attempt
to resolve that inconsistency; it treats GPL-3.0 as authoritative, per the
upstream repository's current stated license, and retains every original
per-file copyright notice unchanged. Anyone relying on this fork for
compliance purposes should treat the above as a known open question, not a
resolved determination.

All modifications in this fork are documented above and, per GPL-3.0,
distributed under the same license as the original.

