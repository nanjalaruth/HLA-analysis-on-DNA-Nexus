# HLA-LA on DNAnexus 

This hands-on guide walks participants through extracting HLA reads from CRAMs on **DNAnexus** and then typing HLA alleles with **HLA-LA**. 

> **Audience:** Mexican researchers.
>
> **You will:**
> (1) compile two WDLs to DNAnexus applets
> (2) run read extraction
> (3) run HLA-LA on the extracted reads.

---

### 🧬 HLA (Human Leukocyte Antigen)

The **HLA system** is a group of immune genes on chromosome 6 that help the body recognize “self” vs. “non-self.”

* **Class I (A, B, C):** Help with antigen presentation to CD8 T cells.
* **Class II (DR, DQ, DP):** Help with antigen presentation to CD4 T cells.
* Highly variable — key for **transplant matching**, **disease association**, and **drug response** studies.
  In this workflow, we use **HLA-LA** to identify each sample’s HLA alleles from sequencing data.

---

### ☁️ DNAnexus

**DNAnexus** is a secure, cloud platform for large-scale genomics.
It lets you:

* Store and organize data in *projects*
* Run reproducible workflows (e.g. WDLs) as *applets*
* Scale analyses across samples easily
  We’ll use it here to run **extractReads** and **HLA-LA** in the cloud.

---

## Workflow at a Glance (Intro Visual)

```mermaid
flowchart LR
  CRAM[Input CRAM/BAM files] --> EX[extractReads applet]
  EX --> XCRAM[Extracted CRAM/BAM and CRAI/BAI]
  XCRAM --> HLA[HLA-LA applet]
  HLA --> OUT[HLA genotypes and reports]
  REF[GRCh38 decoy HLA FASTA] -. required .-> EX
  REF -. required .-> HLA
  BED[HLA KIR Immuno BED] -. required .-> EX

  classDef inputNode fill:#E3F2FD,stroke:#1E88E5,stroke-width:2px,color:#0D47A1;
  classDef processNode fill:#E8F5E9,stroke:#43A047,stroke-width:2px,color:#1B5E20;
  classDef outputNode fill:#FFF3E0,stroke:#FB8C00,stroke-width:2px,color:#E65100;
  classDef refNode fill:#F3E5F5,stroke:#8E24AA,stroke-width:2px,color:#4A148C,stroke-dasharray: 5 3;

  class CRAM inputNode;
  class EX,XCRAM,HLA processNode;
  class OUT outputNode;
  class REF,BED refNode;

  linkStyle default stroke:#546E7A,stroke-width:2px;
  linkStyle 4,5 stroke:#8E24AA,stroke-dasharray: 5 3;
```

---

## 🧩 Prerequisites

* DNAnexus project (example: `Genetics-Workshop-Mexico-2025`)
* DNAnexus **dx-toolkit** installed and logged in (`dx login`)
* Java 8+ for `dxCompiler`
* Reference FASTA: `GRCh38_full_analysis_set_plus_decoy_hla.fa` in your project
* Basic shell familiarity

> **Tip:** Keep your DNAnexus web project open to monitor jobs.

---

## Quick Start 

```bash
# (1) Set your project and paths
dx cd 7_HLA_analysis_on_DNA_Nexus
export PROJECT="Genetics-Workshop-Mexico-2025"
export OUTFOLDER="Outputs"
export REF="$PROJECT:/7_HLA_analysis_on_DNA_Nexus/GRCh38_full_analysis_set_plus_decoy_hla.fa"

# (2) Create output folder
dx mkdir -p "$OUTFOLDER"

# (3) Download dxCompiler (v2.14.0)
wget -q \
  https://github.com/dnanexus/dxCompiler/releases/download/2.14.0/dxCompiler-2.14.0.jar \
  -O dxCompiler-2.14.0.jar
```

---

## Part 1 — Extract HLA Reads

### 1. Upload the Samtools container

```bash
wget -O docker-samtools-1.3.tar.gz \
  'https://www.dropbox.com/scl/fi/2p10uuv5ovyz5ku5k72h0/docker-samtools-1.3.tar.gz?rlkey=q4qul96p8t8bq5i72e4lc6v9s&dl=1'

dx upload docker-samtools-1.3.tar.gz
```

### 2. Download and edit `extractReads.wdl`

```bash
#Repository is private but this is the source
wget -q \
  https://raw.githubusercontent.com/DiltheyLab/MarieAlexKIR/main/extractReads.wdl \
  -O extractReads.wdl
#Download directly from materials shared

# Edit the WDL line with full path to the samtools:
docker: "dx://Genetics-Workshop-Mexico-2025:/7_HLA_analysis_on_DNA_Nexus/docker-samtools-1.3.tar.gz"
```

### 3. Compile to DNAnexus applet

```bash
java -jar dxCompiler-2.14.0.jar compile extractReads.wdl -f
```

### 4. Upload BED and create folder

```bash
wget -q \
  https://raw.githubusercontent.com/DiltheyLab/MarieAlexKIR/main/HLA_and_KIR_and_Immuno.bed \
  -O HLA_and_KIR_and_Immuno.bed

dx upload HLA_and_KIR_and_Immuno.bed
export BED="$PROJECT:/7_HLA_analysis_on_DNA_Nexus/HLA_and_KIR_and_Immuno.bed"
```

### 5. Run `extractReads`

**Single sample example:**

```bash
export SAMPLE="$PROJECT:/Data/NA11995.mapped.ILLUMINA.bwa.CEU.low_coverage.20120522.bam.cram"

dx run /extractReads \
  -ireference="$REF" \
  -itargetRegions="$BED" \
  -imapped_read="$SAMPLE" \
  --folder="$PROJECT:/$OUTFOLDER"
```

**Multiple samples (loop):**

```bash
SAMPLES=( \
  "$PROJECT:/Data/*.cram" \
)

for s in "${SAMPLES[@]}"; do
  dx run --priority low /extractReads \
    -ireference="$REF" \
    -itargetRegions="$BED" \
    -imapped_read="$s" \
    --folder="$PROJECT:/$OUTFOLDER" -y
done
```

---

## Part 2 — Run HLA-LA

### 1. Upload HLA-LA container

```bash
wget -O docker-hla-la-1.0.8-fast-cram.tar.gz \
  'https://www.dropbox.com/scl/fi/yeisml3kez9y13wj6agn1/docker-hla-la-1.0.8-fast-cram.tar.gz?rlkey=lk97bvzoghnuqsavf8vh6ncg4&dl=1'

dx upload docker-hla-la-1.0.8-fast-cram.tar.gz
```

### 2. Download and edit `hla-la.wdl`

```bash
wget -q \
  https://raw.githubusercontent.com/DiltheyLab/MarieAlexKIR/main/hla-la.wdl \
  -O hla-la.wdl

# Edit docker line with full path:
# docker: "dx://Genetics-Workshop-Mexico-2025:/7_HLA_analysis_on_DNA_Nexus/docker-hla-la-1.0.8-fast-cram.tar.gz"
```

### 3. Compile to applet

```bash
java -jar dxCompiler-2.14.0.jar compile hla-la.wdl -f
```

### 4. Run HLA-LA (single sample)

```bash
export XCRAM="$PROJECT:/$OUTFOLDER/NA11995.mapped.ILLUMINA.bwa.CEU.low_coverage.20120522.bam_extracted.cram"
export XCRAI="$XCRAM.crai"

dx run --priority high \
  --cost-limit 3 /hla_la \
  -ireference="$REF" \
  -iapplyT1K="false" \
  -iapplyPING="false" \
  -imapped_read="$XCRAM" \
  -imapped_read_index="$XCRAI" \
  --folder="$PROJECT:/$OUTFOLDER"
```

---

## ✅ Outputs

* Extracted CRAMs and CRAIs
* HLA typing results from HLA-LA per sample

---

## 🧪 Useful Commands

```bash
# List project contents
dx ls "$PROJECT:/$OUTFOLDER"

# Monitor jobs
dx watch job-XXXX

# Describe a job
dx describe job-XXXX --verbose
```

---

## 🩺 Troubleshooting

* **File not found:** check full DNAnexus path.
* **Applet name mismatch:** run `dx ls` and adjust names.
* **dxCompiler memory issues:** increase heap (`JAVA_TOOL_OPTIONS=-Xmx4g`).
* **Missing index:** ensure `.crai` is uploaded.
* **Odd sample IDs:** adjust filename trimming in the WDL.

---

## 🔁 Reproducibility

* Save all your commands to a script.
* Record job metadata: `dx describe -j job-XXXX > record.json`.
* Keep container names and compiler versions pinned.

---

## 📚 References

* [DiltheyLab/MarieAlexKIR GitHub](https://github.com/DiltheyLab/MarieAlexKIR)
* [HLA-LA (Nature Communications, 2019)](https://www.nature.com/articles/s41467-019-11167-x)
* [DNAnexus Documentation](https://documentation.dnanexus.com)

---

### 📎 Appendix: Minimal End-to-End (Copy/Paste)

```bash
# Setup
export PROJECT="Genetics-Workshop-Mexico-2025"
export OUTFOLDER="Outputs-trial"
export REF="$PROJECT:/7_HLA_analysis_on_DNA_Nexus/GRCh38_full_analysis_set_plus_decoy_hla.fa"

dx mkdir -p "$OUTFOLDER"

wget -q \
  https://github.com/dnanexus/dxCompiler/releases/download/2.14.0/dxCompiler-2.14.0.jar \
  -O dxCompiler-2.14.0.jar

# Part 1: extractReads
wget -O docker-samtools-1.3.tar.gz \
  'https://www.dropbox.com/scl/fi/2p10uuv5ovyz5ku5k72h0/docker-samtools-1.3.tar.gz?rlkey=q4qul96p8t8bq5i72e4lc6v9s&dl=1'

dx upload docker-samtools-1.3.tar.gz

wget -q \
  https://raw.githubusercontent.com/DiltheyLab/MarieAlexKIR/main/extractReads.wdl \
  -O extractReads.wdl

# (Edit docker path in WDL)
java -jar dxCompiler-2.14.0.jar compile extractReads.wdl -f

wget -q \
  https://raw.githubusercontent.com/DiltheyLab/MarieAlexKIR/main/HLA_and_KIR_and_Immuno.bed \
  -O HLA_and_KIR_and_Immuno.bed

dx upload HLA_and_KIR_and_Immuno.bed
export BED="$PROJECT:/7_HLA_analysis_on_DNA_Nexus/HLA_and_KIR_and_Immuno.bed"

export SAMPLE="$PROJECT:/Data/NA11995.mapped.ILLUMINA.bwa.CEU.low_coverage.20120522.bam.cram"

dx run /extractReads \
  -ireference="$REF" \
  -itargetRegions="$BED" \
  -imapped_read="$SAMPLE" \
  --folder="$PROJECT:/$OUTFOLDER"

# Part 2: HLA-LA
wget -O docker-hla-la-1.0.8-fast-cram.tar.gz \
  'https://www.dropbox.com/scl/fi/yeisml3kez9y13wj6agn1/docker-hla-la-1.0.8-fast-cram.tar.gz?rlkey=lk97bvzoghnuqsavf8vh6ncg4&dl=1'

dx upload docker-hla-la-1.0.8-fast-cram.tar.gz

wget -q \
  https://raw.githubusercontent.com/DiltheyLab/MarieAlexKIR/main/hla-la.wdl \
  -O hla-la.wdl

# (Edit docker path in WDL)
java -jar dxCompiler-2.14.0.jar compile hla-la.wdl -f

export XCRAM="$PROJECT:/$OUTFOLDER/NA11995.mapped.ILLUMINA.bwa.CEU.low_coverage.20120522.bam_extracted.cram"
export XCRAI="$XCRAM.crai"

dx run --priority high \
  --cost-limit 3 /hla_la \
  -ireference="$REF" \
  -iapplyT1K="false" \
  -iapplyPING="false" \
  -imapped_read="$XCRAM" \
  -imapped_read_index="$XCRAI" \
  --folder="$PROJECT:/$OUTFOLDER"
```
