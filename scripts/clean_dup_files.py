#!/usr/bin/env python3

import argparse
import subprocess
import sys
import os
from collections import defaultdict
from datetime import datetime
from typing import List, Dict, Tuple, Optional

def check_dx_available():
    """Check if dx command is available and user is authenticated."""
    try:
        # Check if dx command exists
        subprocess.run(["dx", "--version"], check=True, capture_output=True)
        
        # Check if user is authenticated
        subprocess.run(["dx", "whoami"], check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError:
        return False
    except FileNotFoundError:
        return False

def validate_dx_path(path: str) -> bool:
    """Validate that the given dx path exists and is accessible."""
    try:
        result = subprocess.run(["dx", "ls", path], capture_output=True, text=True)
        return result.returncode == 0
    except Exception:
        return False

def get_file_list_with_dates(dx_path: str) -> List[str]:
    """Get list of files with modification dates using dx ls -l."""
    try:
        result = subprocess.run(["dx", "ls", "-l", dx_path], capture_output=True, text=True, check=True)
        lines = []
        for line in result.stdout.strip().split('\n'):
            if line and not line.startswith('d'):  # Exclude directories
                lines.append(line.strip())
        return lines
    except subprocess.CalledProcessError as e:
        print(f"Error listing files in {dx_path}: {e}")
        return []

def parse_dx_ls_line(line: str) -> Tuple[Optional[str], Optional[str], Optional[str]]:
    """Parse a line from dx ls -l output.
    
    Format: permissions links owner group size date time filename (file_id)
    Returns: (filename, date_time, file_id)
    """
    parts = line.split()
    if len(parts) < 7:
        return None, None, None
    
    # Last field is the file ID in parentheses format (file-123456)
    file_id_with_parens = parts[-1]
    # Remove parentheses to get the actual file ID
    if file_id_with_parens.startswith('(') and file_id_with_parens.endswith(')'):
        file_id = file_id_with_parens[1:-1]  # Remove ( and )
    else:
        file_id = file_id_with_parens
    
    # Second to last field is the filename
    filename = parts[-2]
    # 6th and 7th fields are date and time (now -4 and -3 since we have filename and file_id at the end)
    date_time = f"{parts[-4]} {parts[-3]}"
    
    return filename, date_time, file_id

def parse_date_time(date_time_str: str) -> datetime:
    """Parse date time string from dx ls -l output."""
    try:
        # Handle different date formats that might appear in dx ls -l
        # Common formats: "Mar 15 10:30", "2024-03-15 10:30:45"
        if '-' in date_time_str:
            # ISO format: "2024-03-15 10:30:45"
            return datetime.strptime(date_time_str, "%Y-%m-%d %H:%M:%S")
        else:
            # Standard format: "Mar 15 10:30"
            current_year = datetime.now().year
            date_time_with_year = f"{date_time_str} {current_year}"
            return datetime.strptime(date_time_with_year, "%b %d %H:%M %Y")
    except ValueError:
        # If parsing fails, return a very old date so it gets deleted
        return datetime(1900, 1, 1)

def find_duplicates(dx_path: str) -> List[List[str]]:
    """Find duplicate files by name, keeping only the latest version."""
    print("Detecting duplicate files by name...")
    file_lines = get_file_list_with_dates(dx_path)
    
    # Group files by basename
    name_groups = defaultdict(list)
    
    for line in file_lines:
        filename, date_time, file_id = parse_dx_ls_line(line)
        if filename and date_time and file_id:
            basename = os.path.basename(filename)
            name_groups[basename].append((file_id, date_time))
    
    # Find groups with multiple files and identify which to delete
    duplicates_to_delete = []
    
    for basename, file_list in name_groups.items():
        if len(file_list) > 1:
            print(f"Found {len(file_list)} files with name: {basename}")
            
            # Sort by date (latest first)
            file_list.sort(key=lambda x: parse_date_time(x[1]), reverse=True)
            
            # Keep the first (latest) file, delete the rest
            latest_file_id = file_list[0][0]
            files_to_delete = [file_id for file_id, _ in file_list[1:]]
            
            print(f"  Keeping: {latest_file_id} (latest)")
            for file_id in files_to_delete:
                print(f"  Will delete: {file_id}")
            
            if files_to_delete:
                duplicates_to_delete.append(files_to_delete)
    
    return duplicates_to_delete

def delete_duplicates(duplicates: List[List[str]], dry_run: bool = False) -> int:
    """Delete duplicate files."""
    deleted_count = 0
    
    for group in duplicates:
        if not group:
            continue
            
        print(f"Processing group of {len(group)} files to delete:")
        for file_id in group:
            if dry_run:
                print(f"  Would delete: {file_id}")
            else:
                print(f"  Deleting: {file_id}")
                try:
                    subprocess.run(["dx", "rm", file_id], check=True, capture_output=True)
                    deleted_count += 1
                except subprocess.CalledProcessError as e:
                    print(f"    Error deleting {file_id}: {e}")
        print("---")
    
    if dry_run:
        print(f"Dry run complete. Would delete {deleted_count} files.")
    else:
        print(f"Deletion complete. Deleted {deleted_count} files.")
    
    return deleted_count

def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description='Detect and delete duplicate files on a given dx path, keeping only the latest version',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
This script handles DNAnexus behavior where files with the same name create separate objects.
It keeps only the latest version based on modification date.

Examples:
  %(prog)s --path "/users/username/data" --dry-run
  %(prog)s --path "/users/username/data"
        """
    )
    
    parser.add_argument(
        '--path', 
        required=True,
        help='The dx path to scan for duplicates'
    )
    
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be deleted without actually deleting'
    )
    
    return parser.parse_args()

def main():
    """Main function."""
    args = parse_arguments()
    
    print("=== Duplicate File Cleanup Script ===")
    print(f"Path: {args.path}")
    print(f"Dry run: {args.dry_run}")
    print()
    
    # Check prerequisites
    if not check_dx_available():
        print("Error: dx command not found or not authenticated.")
        print("Please install DNAnexus CLI and run 'dx login' first.")
        sys.exit(1)
    
    if not validate_dx_path(args.path):
        print(f"Error: Invalid dx path: {args.path}")
        sys.exit(1)
    
    # Find duplicates
    duplicates = find_duplicates(args.path)
    
    # Check if any duplicates were found
    if not duplicates:
        print("No duplicates found.")
        return
    
    print(f"Found {len(duplicates)} groups of duplicate files.")
    
    # Ask for confirmation if not dry run
    if not args.dry_run:
        response = input("\nDo you want to proceed with deletion? (y/N): ")
        if response.lower() not in ['y', 'yes']:
            print("Operation cancelled.")
            return
    
    # Delete duplicates
    delete_duplicates(duplicates, args.dry_run)
    
    print("=== Script completed ===")

if __name__ == "__main__":
    main() 