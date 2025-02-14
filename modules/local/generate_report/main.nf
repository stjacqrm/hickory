process GENERATE_REPORT{
  tag {"Generating Report"}
  label 'process_medium'
  
  input:
  path samtools_cvg_tsvs

  output:
  path "*hickory_read_map_summary*"  , emit: hickory_read_map_summary

  script:
  """
#!/usr/bin/env python3
import os, sys
import glob, csv
import xml.etree.ElementTree as ET
from datetime import datetime

today = datetime.today()
today = today.strftime("%m%d%y")

class result_values:
    def __init__(self,id):
        self.id = id
        self.aligned_bases = "NA"
        self.percent_cvg = "NA"
        self.mean_depth = "NA"
        self.mean_base_q = "NA"
        self.mean_map_q = "NA"

#get list of result files
samtools_results = glob.glob("*.samtools.cvg.tsv")
results = {}

# collect samtools results
for file in samtools_results:
    id = file.split(".samtools.cvg.tsv")[0]
    result = result_values(id)
    with open(file,'r') as tsv_file:
        tsv_reader = list(csv.DictReader(tsv_file, delimiter="\t"))
        for line in tsv_reader:
            result.aligned_bases = line["covbases"]
            result.percent_cvg = line["coverage"]
            result.mean_depth = line["meandepth"]
            result.mean_base_q = line["meanbaseq"]
            result.mean_map_q = line["meanmapq"]

    results[id] = result

#create output file
with open(f"hickory_read_map_summary_{today}.csv",'w') as csvout:
    writer = csv.writer(csvout,delimiter=',')
    writer.writerow(["sample","aligned_bases","percent_cvg", "mean_depth", "mean_base_q", "mean_map_q"])
    for id in results:
        result = results[id]
        writer.writerow([result.id,result.aligned_bases,result.percent_cvg,result.mean_depth,result.mean_base_q,result.mean_map_q])
  """
}