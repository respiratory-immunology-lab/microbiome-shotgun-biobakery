#!/bin/bash
#SBATCH --job-name=KneadData
#SBATCH --account=of33
#SBATCH --time=3-00:00:00
#SBATCH --ntasks=36
#SBATCH --mem=200G

# Load necessary environment and modules
source activate biobakery3
module load gnuparallel

# Create output directory
mkdir kneaddata_output

# Run KneadData in parallel
for f in rawfastq/*_R1.fastq.gz
do
  Basename=${f%_R*}
  echo kneaddata -t 6 --input ${Basename}_R1.fastq.gz --input ${Basename}_R2.fastq.gz \
  --remove-intermediate-output --bypass-trf --output kneaddata_output \
  --trimmomatic /home/cpat0003/miniconda3/envs/biobakery3/bin/Trimmomatic-0.33 \
  -db /home/cpat0003/of33/Databases/shotgun/host/human/hg37dec_v0.1
done | parallel -j 6
