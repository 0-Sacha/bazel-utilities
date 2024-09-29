#!/usr/bin/env python3

import os
import shutil
import subprocess
import glob
import argparse
import json

def replace_files(workspace_root, files_list, dry_run = False):
    formatted_file_dir = os.path.join(workspace_root, "bazel-bin", "clang_format")
    if not os.path.exists(formatted_file_dir):
        print("\033[0;31m", ">>> No ClangFormat folder found at {} !".format(formatted_file_dir), "\033[0m")
        return []

    for file in files_list:
        src_file = os.path.join(formatted_file_dir, file)
        diff_file = os.path.join(formatted_file_dir, file + ".diff")
        dst_file = os.path.join(workspace_root, file)
        
        if not os.path.exists(dst_file):
            print("\033[0;31m", ">>> Try to update a file that doesn't exist: {} !".format(dst_file), "\033[0m")
            continue

        if os.path.getsize(diff_file) == 0:
            continue
        
        print(f"  * {src_file} -> {dst_file}")
        if dry_run == False:
            shutil.copy2(src_file, dst_file)

def main():
    parser = argparse.ArgumentParser(description='Apply all changes computed by the clang-format aspect to the project')
    parser.add_argument('--dry_run', default=False, help='dry run, only show actions that will be done')
    args = parser.parse_args()
        
    workspace_root = os.getenv('BUILD_WORKSPACE_DIRECTORY')

    print("\033[0;32m", ">>> Launch ClangFormatApply on {} {}!".format(workspace_root, "as dry-run " if args.dry_run else ""), "\033[0m")

    for exec_report_file in glob.glob(os.path.join(workspace_root, "bazel-bin", "clang_format", '*.exec_report.json')):
        files_list = []
        with open(exec_report_file) as exec_report_content:
            files_list = json.load(exec_report_content)
            exec_report_content.close()
        print("\033[0;32m", "    - {}".format(os.path.basename(exec_report_file).replace('.exec_report.json', '')), "\033[0m")
        replace_files(workspace_root, files_list, args.dry_run)
    

if __name__ == "__main__":
    main()
