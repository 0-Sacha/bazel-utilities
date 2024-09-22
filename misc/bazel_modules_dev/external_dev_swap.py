import re
import argparse
import shutil

def main():
    parser = argparse.ArgumentParser(description="Swap http_archive to local_repository entries in the WORKSPACE file.")
    parser.add_argument("WORKSPACE", help="Path to the WORKSPACE file")
    parser.add_argument("--local_repo_prefix", default="external_dev", help="Prefix for the path to the local_repositories (default: external_dev)")
    parser.add_argument("bazel_modules", nargs='+', help="List of names to swap (e.g., bazel_utilities bazel_arm bazel_stm32)")

    args = parser.parse_args()

    shutil.copy(args.WORKSPACE, args.WORKSPACE + ".tmp")

    with open(args.WORKSPACE, "r") as WKFile:
        WKFileContent = WKFile.read()

    for module in args.bazel_modules:
        module_pattern = re.compile(
            rf"(http_archive\(\s*name\s*=\s*\"({module})\"(.*?)\))",
            re.DOTALL
        )

        module_found = module_pattern.findall(WKFileContent)
        WKFileContent = WKFileContent.replace(
            module_found[0][0],
            f"local_repository(\n    name = \"{module}\",\n    path = \"./external_dev/{module}\"\n)"
        )

    with open(args.WORKSPACE, "w") as WKFile:
        WKFile.write(WKFileContent)
        
if __name__ == "__main__":
    main()
