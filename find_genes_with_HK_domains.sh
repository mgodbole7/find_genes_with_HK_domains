#! /bin/bash
# usage: ./find_genes_with_HKdomains.sh <query file (fasta)> <assembly dir> <genome BED dir> <output dir>
# note: renamed to ./mgodbole7.sh for assignment submission purposes

queryfile="$1"
assembly_dir="$2"
genome_bed_dir="$3"
output_dir="$4"

mkdir -p "$output_dir"

# loop through the .bed files in the genome_bed_dir
for genome_bed_file in "$genome_bed_dir"/*.bed; do
    genome_name="$(basename "${genome_bed_file%.*}")"
    output_file="${output_dir}/${genome_name}_genes_with_HKdomains.txt"
    subject_file="${assembly_dir}/${genome_name}.fna"

    # perform tblastn
    tblastn \
        -query "$queryfile" \
        -subject "$subject_file" \
        -outfmt "6 std qlen" \
        -task tblastn-fast \
        | awk -v OFS='\t' -v genome_name="$genome_name" -v output_file="$output_file" -v genome_bed_file="$genome_bed_file" '
            $3>30 && $4>0.9*$13 {
                # Parse the blast output
                query_id=$1
                subject_id=$2
                start=$9
                end=$10

                # Read the corresponding BED file
                while ((getline < genome_bed_file) > 0) {
                    if ($1 == subject_id && start >= $2 && end <= $3) {
                        # The segment is within this gene
                        print $4
                    }
                }
                close(genome_bed_file)
            }
        ' | sort -k2,2 | uniq > "$output_file"

    # count number of unique genes identified
    num_genes=$(wc -l < "$output_file")
    echo "$genome_name contains $num_genes genes"
done
