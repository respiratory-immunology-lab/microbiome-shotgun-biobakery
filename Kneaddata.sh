#!/bin/bash
#SBATCH --job-name=KneadData
#SBATCH --account=of33
#SBATCH --time=3-00:00:00
#SBATCH --ntasks=36
#SBATCH --mem=200G

# Load necessary environment and modules
source activate biobakery3
module load gnuparallel

# Run KneadData in parallel
mkdir kneaddata_output
for f in rawfastq/*_R1.fastq.gz
do
  Basename=${f%_R*}
  echo kneaddata -t 6 -p 6 --input ${Basename}_R1.fastq.gz --input ${Basename}_R2.fastq.gz \
  --remove-intermediate-output --bypass-trf --output kneaddata_output \
  --trimmomatic /home/cpat0003/miniconda3/envs/biobakery3/bin/Trimmomatic-0.33 \
  -db ~/of33/Databases/shotgun/host/human/hg37dec_v0.1
done | parallel -j 4

# Extract reads information and create a count file
for f in *.log
do
  Basename=${f%_merged*}
  Name=$Basename
  Human=$(sed -n 's/hg37dec_v0.1_bowtie2_paired_contam_1.fastq\(.*\).0/\1/p' $f | sed 's/.*: //')
  Microbial=$(sed -n 's/R1_kneaddata_paired_1.fastq\(.*\).0/\1/p' $f | sed 's/.*: //')
  echo $Name $Human $Microbial
done > counts.txt
