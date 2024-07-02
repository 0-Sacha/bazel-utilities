#!/usr/bin/env python3

import os
import shutil
import subprocess
import argparse

def replace_files(target_dir, format_dir):
    for root, dirs, files in os.walk(format_dir):
        rel_path = os.path.relpath(root, format_dir)
        target_path = os.path.join(target_dir, rel_path)

        if not os.path.exists(target_path):
            continue

        for file in files:
            src_file = os.path.join(root, file)
            dst_file = os.path.join(target_path, file)
            
            if not os.path.exists(dst_file):
                continue

            print(f"ClangFormat Applied: {dst_file}")
            shutil.copy2(src_file, dst_file)

def exec_clang_format(target, local):
    args = [
        "bazelisk", "build", target,
        "--aspects=@bazel_utilities//tools:clang_format.bzl%clang_format", "--output_groups=+report"
    ]
    if local:
        args.append("--spawn_strategy=local")
    result = subprocess.run(args, text=True)

def clang_format_directory():
    result = subprocess.run(["bazelisk", "info", "bazel-bin"], stdout=subprocess.PIPE, text=True)
    format_directory = os.path.join(result.stdout.strip(), "clang_format")
    return format_directory

def main():
    parser = argparse.ArgumentParser(description='Apply clang-format to the project using bazel_utilities clang-format support')
    parser.add_argument('-t', '--target', required=True, help='Name of the target')
    parser.add_argument('--local', action='store_true', help='Use local clang-format')
    args = parser.parse_args()

    # exec_clang_format(args.target, args.local)

    clang_format_dir = clang_format_directory()
    project_dir = '.'

    if not clang_format_dir:
        print("Error: 'bazelisk info bazel-bin' did not return a valid directory.")
        return
    if not os.path.exists(clang_format_dir):
        print(f"Error: Format directory '{clang_format_dir}' does not exist.")
        return

    replace_files(project_dir, clang_format_dir)

if __name__ == "__main__":
    main()
