#!/bin/bash
#SBATCH --job-name=KneadData
#SBATCH --account=of33
#SBATCH --time=1-00:00:00
#SBATCH --cores=4
#SBATCH --ntasks=8
#SBATCH --mem=200G

# Get options set by flags
while getopts ':ht:d:l:i:o:' flag; do
  case "${flag}" in
    h ) 
      echo "Usage:"
      echo "test_script.sh -h			Display this help message."
      echo "test_script.sh -t			Provide the Trimmomatic folder location."
      echo "test_script.sh -d			Provide the hg37dec database folder location."
      echo "test_script.sh -l			Provide a file with locations for Trimmomatic"
      echo "					and the hg37dec database"
      echo "					File should contain space-separated variables"
      echo "					trimmomatic and humangenomeDB on separate lines."
      echo "					DO NOT PROVIDE -t/-d IF PROVIDING -l!"
      echo "test_script.sh -i			Provide an input folder"
      echo "test_script.sh -o			Provide an output folder"
      exit 0 
      ;;
    t ) 
      trimmomatic=("$OPTARG")
      echo "Trimmomatic location:             $trimmomatic"
      ;;
    d )
      humanDB=("$OPTARG")
      echo "Human genome database location:   $humanDB"
      ;;
    l )
      loc_file=("$OPTARG")
      trimmomatic=$(cat $loc_file | sed -n 's/trimmomatic //p')
      humanDB=$(cat $loc_file | sed -n 's/humangenomeDB //p')
      echo "Trimmomatic location:             $trimmomatic"
      echo "Human genome database location:   $humanDB"
      ;;
    i )
      input=("$OPTARG")
      ;;
    o )
      output=("$OPTARG")
      ;;
    \? ) 
      echo "Invalid option: -$OPTARG" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))



#Load necessary environment and modules
source activate biobakery3
module load gnuparallel

# Run KneadData in parallel
for f in $input/*_R1_001.fastq.gz
do
  Basename=${f%_R*}
  echo kneaddata -t 6 -p 6 --input ${Basename}_R1_001.fastq.gz --input ${Basename}_R2_001.fastq.gz \
  --remove-intermediate-output --output $output \
  --trimmomatic $trimmomatic \
  -db $humanDB
done | parallel -j 4

# Remove contaminant files to increase space
rm -rf $output/*contam*

# Extract human and non human read numbers from log files
for f in $output/*.log
do
  Basename=${f%_R1_001*}
  Samplename=${Basename#*/}
  Human=$(sed -n 's/hg37dec_v0.1_bowtie2_paired_contam_1.fastq\(.*\).0/\1/p' $f | sed 's/.*: //')
  Microbial=$(sed -n 's/R1_001_kneaddata_paired_1.fastq\(.*\).0/\1/p' $f | sed 's/.*: //')
  echo $Samplename $Human $Microbial
done > $output/read_counts.txt
