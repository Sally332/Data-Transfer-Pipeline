#!/bin/bash

# Create Nextflow Project Directory
PROJECT_DIR="Genomic_Data_Transfer_Pipeline"
RAW_DATA_DIR="$PROJECT_DIR/Raw_Data"
PROCESSED_DATA_DIR="$PROJECT_DIR/Processed_Data"
ARCHIVE_DIR="$PROJECT_DIR/Archives"
LOG_DIR="$PROJECT_DIR/Logs"
CHECKSUM_DIR="$PROJECT_DIR/Checksums"
SCRIPTS_DIR="$PROJECT_DIR/Scripts"
CONFIG_DIR="$PROJECT_DIR/Config"

mkdir -p $RAW_DATA_DIR $PROCESSED_DATA_DIR $ARCHIVE_DIR $LOG_DIR $CHECKSUM_DIR $SCRIPTS_DIR $CONFIG_DIR

# Create sample Nextflow config file
cat <<EOL > $CONFIG_DIR/nextflow.config
params {
  project_dir = "$PROJECT_DIR"
  raw_data_dir = "$RAW_DATA_DIR"
  processed_data_dir = "$PROCESSED_DATA_DIR"
  archive_dir = "$ARCHIVE_DIR"
  log_dir = "$LOG_DIR"
  checksum_dir = "$CHECKSUM_DIR"
}

globals {
  compress_format = "tar.gz"
  checksum_algo = "sha256sum"
}

process {
  executor = "local"
  cpus = 4
  memory = "8 GB"
}
EOL

# Create basic Nextflow script
cat <<EOL > $SCRIPTS_DIR/main.nf
#!/usr/bin/env nextflow

params.project_dir = "$PROJECT_DIR"
params.raw_data_dir = "$RAW_DATA_DIR"
params.processed_data_dir = "$PROCESSED_DATA_DIR"
params.archive_dir = "$ARCHIVE_DIR"
params.log_dir = "$LOG_DIR"
params.checksum_dir = "$CHECKSUM_DIR"

globals.compress_format = "tar.gz"
globals.checksum_algo = "sha256sum"

process CompressRawData {
  input:
    path raw_file from file("$RAW_DATA_DIR/*.fastq")

  output:
    path archive_file into compressed_files

  script:
    archive_file = "$ARCHIVE_DIR/" + raw_file.baseName + "." + globals.compress_format
    """
    tar -czf \$archive_file \$raw_file
    """
}

process GenerateChecksums {
  input:
    path archive_file from compressed_files

  output:
    path checksum_file into checksum_files

  script:
    checksum_file = "$CHECKSUM_DIR/" + archive_file.baseName + ".sha256"
    """
    \$globals.checksum_algo \$archive_file > \$checksum_file
    """
}

workflow {

  // Create log directory if it doesn't exist
  log_file = file(params.log_dir + '/pipeline.log')
  log_file.write('Pipeline started at: ' + new Date() + '
')

  try {
    // Compress raw data
    compressed_files = CompressRawData()
    log_file.append('Compressed ' + compressed_files.size() + ' files.
')

    // Generate checksums
    checksum_files = GenerateChecksums(compressed_files)
    log_file.append('Generated ' + checksum_files.size() + ' checksum files.
')

    // Prepare batch transfer lists for Globus
    transfer_list_file = file(params.project_dir + '/transfer_list.txt')
    transfer_list_file.write(compressed_files.join('
') + '
')
    log_file.append('Created transfer list at: ' + transfer_list_file.absolutePath + '
')

    // Send email notification on completion
    email_body = '''
    Pipeline completed successfully.
    Total compressed files: ''' + compressed_files.size() + '''
    Total checksum files: ''' + checksum_files.size() + '''
    Transfer list created at: ''' + transfer_list_file.absolutePath + '''
    '''
    """
    echo "$email_body" | mail -s "Nextflow Pipeline Status" your.email@example.com
    """

    // Print a summary
    println "
Data transfer preparation complete."
    println "Total compressed files: " + compressed_files.size()
    println "Checksum files generated: " + checksum_files.size()
    println "Transfer list created at: " + transfer_list_file.absolutePath
    log_file.append('Pipeline completed successfully at: ' + new Date() + '
')
  } catch (Exception e) {
    log_file.append('Pipeline failed at: ' + new Date() + '
')
    log_file.append('Error message: ' + e.message + '
')
    println "Error encountered. Check pipeline.log for details."
    exit 1
  }
}

  // Create log directory if it doesn't exist
  log_file = file(params.log_dir + '/pipeline.log')
  log_file.write('Pipeline started at: ' + new Date() + '
')

  try {
    // Compress raw data
    compressed_files = CompressRawData()
    log_file.append('Compressed ' + compressed_files.size() + ' files.
')

    // Generate checksums
    checksum_files = GenerateChecksums(compressed_files)
    log_file.append('Generated ' + checksum_files.size() + ' checksum files.
')

    // Prepare batch transfer lists for Globus
    transfer_list_file = file(params.project_dir + '/transfer_list.txt')
    transfer_list_file.write(compressed_files.join('
') + '
')
    log_file.append('Created transfer list at: ' + transfer_list_file.absolutePath + '
')

    // Print a summary
    println "
Data transfer preparation complete."
    println "Total compressed files: " + compressed_files.size()
    println "Checksum files generated: " + checksum_files.size()
    println "Transfer list created at: " + transfer_list_file.absolutePath
    log_file.append('Pipeline completed successfully at: ' + new Date() + '
')
  } catch (Exception e) {
    log_file.append('Pipeline failed at: ' + new Date() + '
')
    log_file.append('Error message: ' + e.message + '
')
    println "Error encountered. Check pipeline.log for details."
    exit 1
  }
}
  compressed_files = CompressRawData()
  checksum_files = GenerateChecksums(compressed_files)

  // Prepare batch transfer lists for Globus
  transfer_list_file = file(params.project_dir + '/transfer_list.txt')
  transfer_list_file.write(compressed_files.join('
') + '
')

  // Print a summary
  println "
Data transfer preparation complete."
  println "Total compressed files: " + compressed_files.size()
  println "Checksum files generated: " + checksum_files.size()
  println "Transfer list created at: " + transfer_list_file.absolutePath
}
EOL

chmod +x $SCRIPTS_DIR/main.nf

# Print message
echo "Nextflow data transfer pipeline created successfully."
echo "Run the pipeline with: nextflow run $SCRIPTS_DIR/main.nf -c $CONFIG_DIR/nextflow.config"

