import re
import argparse
import shutil

def main():
    parser = argparse.ArgumentParser(description="Swap git_override to local_path_override entries in the MODULE file.")
    parser.add_argument("MODULE", help="Path to the MODULE.bazel file")
    parser.add_argument("--local_repo_prefix", default="external_dev", help="Prefix for the path to the local_repositories (default: external_dev)")
    parser.add_argument("bazel_modules", nargs='+', help="List of names to swap (e.g., bazel_utilities bazel_arm bazel_stm32)")

    args = parser.parse_args()

    shutil.copy(args.MODULE, args.MODULE + ".tmp")

    with open(args.MODULE, "r") as ModFile:
        ModFileContent = ModFile.read()

    for module in args.bazel_modules:
        module_pattern = re.compile(
            rf"(git_override\(\s*module_name\s*=\s*\"({module})\"(.*?)\))",
            re.DOTALL
        )

        module_found = module_pattern.findall(ModFileContent)
        ModFileContent = ModFileContent.replace(
            module_found[0][0],
            f"local_path_override(\n    module_name = \"{module}\",\n    path = \"./external_dev/{module}\"\n)"
        )

    with open(args.MODULE, "w") as ModFile:
        ModFile.write(ModFileContent)
        
if __name__ == "__main__":
    main()
