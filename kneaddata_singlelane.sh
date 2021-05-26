#!/bin/bash
#SBATCH --job-name=KneadData
#SBATCH --account=of33
#SBATCH --time=3-00:00:00
#SBATCH --cores=4
#SBATCH --ntasks=8
#SBATCH --mem=200G

# Load necessary environment and modules
source activate biobakery3
module load gnuparallel

# Run KneadData in parallel
for f in rawfastq/*_R1_001.fastq.gz
do
  Basename=${f%_R*}
  echo kneaddata -t 6 -p 6 --input ${Basename}_R1_001.fastq.gz --input ${Basename}_R2_001.fastq.gz \
  --remove-intermediate-output --output kneaddata_output \
  --trimmomatic /home/mmacowan/mf33_scratch/Matt/share/Trimmomatic-0.33 \
  -db /home/mmacowan/of33/Databases/shotgun/host/human/hg37dec_v0.1
done | parallel -j 4

# Remove contaminant files to increase space
rm -rf *contam*

# Extract human and non human read numbers from log files
for f in kneaddata_output/*.log
do
  Basename=${f%_R1_001*}
  Samplename=${Basename#*/}
  Human=$(sed -n 's/hg37dec_v0.1_bowtie2_paired_contam_1.fastq\(.*\).0/\1/p' $f | sed 's/.*: //')
  Microbial=$(sed -n 's/R1_001_kneaddata_paired_1.fastq\(.*\).0/\1/p' $f | sed 's/.*: //')
  echo $Samplename $Human $Microbial
done > kneaddata_output/read_counts.txt
