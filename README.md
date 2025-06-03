# Data Transfer Pipeline

## 1. Overview
This Nextflow‐based pipeline moves large genomic files between HPC/storage, verifies checksums, and retries failed transfers automatically.

## 2. Key Features
- Chunked uploads/downloads with checksum verification
- Automatic retry on network drop
- Configurable source (e.g. S3, Globus) and destination (HPC path)
- Logging of transfer status and errors

## 3. Prerequisites
- Java ≥ 8
- Nextflow ≥ 20.10  
- Access credentials for source/destination endpoints (e.g. Globus endpoint IDs)
- (Optional) Globus CLI installed

## 4. Quick Start
1. Clone the repo:
   ```bash
   git clone https://github.com/<YOUR-USERNAME>/Data-Transfer-Pipeline.git
   cd Data-Transfer-Pipeline

## For full documentation, see docs/README.pdf
