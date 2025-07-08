#!/usr/bin/env python3
"""
DNAnexus launcher for BHR preprocessing script.
This script launches the BHR preprocessing job on DNAnexus using swiss-army-knife.
"""

import argparse
import os
import subprocess
import sys

def parse_args():
    parser = argparse.ArgumentParser(description='Launch BHR preprocessing on DNAnexus')
    parser.add_argument('--input_file', required=True, 
                       help='Path to the input association file on DNAnexus')
    parser.add_argument('--output_file', required=True, 
                       help='Output file on DNAnexus')
    parser.add_argument('--annot_file', 
                       default='/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/helper_files/ukb23158_500k_OQFE.annotations.txt.gz',
                       help='Path to the annotation file (default: UKB annotation file)')
    parser.add_argument('--gen_annot_file',
                       default='/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/helper_files/ukb23158_500k_OQFE.sets.txt.gz',
                       help='Path to the gene annotation file (default: UKB gene sets file)')
    parser.add_argument('--job_name', 
                       help='Name for the DNAnexus job (default: auto-generated)')
    return parser.parse_args()

def main():
    args = parse_args()
    
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    bhr_script_path = os.path.join(script_dir, 'bhr_preprocess.py')
    
    # Check if the BHR preprocessing script exists
    if not os.path.exists(bhr_script_path):
        print(f"Error: BHR preprocessing script not found at {bhr_script_path}")
        sys.exit(1)
    
    # Generate job name if not provided
    if not args.job_name:
        input_basename = os.path.basename(args.input_file)
        job_name = f"bhr_preprocess_{input_basename.replace('.regenie', '')}"
    else:
        job_name = args.job_name
    
    print(f"Input file: {args.input_file}")
    print(f"Output file: {args.output_file}")
    print(f"Annotation file: {args.annot_file}")
    print(f"Gene annotation file: {args.gen_annot_file}")
    print(f"Job name: {job_name}")
    print(f"BHR script path: {bhr_script_path}")
    
    # First, upload the preprocessing script to DNAnexus
    print("Uploading BHR preprocessing script to DNAnexus...")
    upload_cmd = ['dx', 'upload', bhr_script_path, '--wait', '--brief']
    
    try:
        result = subprocess.run(upload_cmd, check=True, capture_output=True, text=True)
        # Extract the file ID from the upload output
        script_file_id = result.stdout.strip()  # With --brief, this is just the file ID
        print(f"Uploaded script with ID: {script_file_id}")
    except subprocess.CalledProcessError as e:
        print(f"Error uploading script: {e}")
        print(f"Error output: {e.stderr}")
        sys.exit(1)
    
    # Create the command to run the BHR preprocessing script
    # The script will be available in the swiss-army-knife environment
    cmd = f"""
    # Run the preprocessing script
    python bhr_preprocess.py {os.path.basename(args.input_file)} \
        --annot_file {os.path.basename(args.annot_file)} \
        --gen_annot_file {os.path.basename(args.gen_annot_file)} \
        --output_file {os.path.basename(args.output_file)}
  """
    
    # Build the DNAnexus command with all input files
    dx_cmd = [
        'dx', 'run', 'swiss-army-knife',
        f'-iin={args.input_file}',
        f'-iin={script_file_id}',
        f'-iin={args.annot_file}',
        f'-iin={args.gen_annot_file}',
        f'-icmd={cmd}',
        '--name', job_name,
        '--destination', os.path.dirname(args.output_file),
        '--yes',
        '--wait'
    ]
    
    print(f"Executing DNAnexus command: {' '.join(dx_cmd)}")
    
    # Execute the dx command with error handling
    try:
        result = subprocess.run(dx_cmd, check=True)
        print(f"Successfully launched BHR preprocessing job: {job_name}")
    except subprocess.CalledProcessError as e:
        print(f"Error: Command failed with exit code {e.returncode}")
        sys.exit(1)
    finally:
        # Clean up the uploaded script file
        print(f"Cleaning up uploaded script file: {script_file_id}")
        try:
            cleanup_cmd = ['dx', 'rm', script_file_id]
            subprocess.run(cleanup_cmd, check=True)
            print("Successfully removed uploaded script file")
        except subprocess.CalledProcessError as e:
            print(f"Warning: Failed to remove uploaded script file: {e}")
            # Don't exit on cleanup failure, just warn

if __name__ == "__main__":
    main() 