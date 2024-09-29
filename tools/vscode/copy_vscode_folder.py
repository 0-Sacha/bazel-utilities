#!/usr/bin/env python3

import os
import shutil
import json
import argparse

def main():
    parser = argparse.ArgumentParser(description='Copy a generated vscode folder as the main .vscode of the WORKSPACE')
    parser.add_argument('--gen_folder', help='The vscode folder to copy')
    args = parser.parse_args()
        
    workspace_root = os.getenv('BUILD_WORKSPACE_DIRECTORY')

    print("\033[0;32m", ">>> Copy vscode file !", "\033[0m")

    shutil.copytree("bazel-bin/" + args.gen_folder, workspace_root + "/.vscode")

if __name__ == "__main__":
    main()
