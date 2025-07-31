from Bio import SeqIO

new_header_dict = {}
for line in lines:
    if line.startswith('#'):
        continue
    parts = line.split('\t')
    name = parts[2]
    mtype = parts[3]
    ncbi_id = parts[6]
    length = parts[8]
    circular = "true" if name.startswith('c') else "false"
    if mtype == "Chromosome":
        name = "chromosome"
    new_header_row= f"{name} length={length} circular={circular}"
    new_header_dict[ncbi_id] = new_header_row

new_recs = []
for rec in SeqIO.parse(genome_raw, "fasta"):
    old_id = rec.id
    rec.id = new_header_dict[old_id].split()[0]
    rec.description = new_header_dict[old_id]
    new_recs.append(rec)

SeqIO.write(new_recs, 'new_headers.fasta', 'fasta')