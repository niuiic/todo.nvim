import subprocess
import re
import os
import concurrent.futures
import sys
import json
from typing import List


# ~ rg
def rg(path: str, pattern: str):

    output = subprocess.run(
        ["rg", pattern, path, "--line-number"], capture_output=True
    ).stdout.decode()
    lines = output.split("\n")

    matched = []
    if os.path.isfile(path):
        for line in lines:
            res = re.match(r"^([\d]+):(.*)$", line)
            if res:
                matched.append(
                    {
                        "path": path,
                        "lnum": int(res.group(1)),
                        "text": res.group(2),
                    }
                )
    else:
        for line in lines:
            res = re.match(r"^([^:]+):([\d]+):(.*)$", line)
            if res:
                matched.append(
                    {
                        "path": res.group(1),
                        "lnum": int(res.group(2)),
                        "text": res.group(3),
                    }
                )

    return matched


def test_rg():
    dir = os.path.join(os.path.dirname(__file__), "test")
    matched = rg(dir, r"\[.*\] \(.*\)\{.*\}: .*")
    print(matched)
    file = os.path.join(os.path.dirname(__file__), "test/task.md")
    matched = rg(file, r"\[.*\] \(.*\)\{.*\}: .*")
    print(matched)


# ~ parse
def parse(str: str, pattern: str, groups: List[str]):
    res = re.match(pattern, str)
    if not res:
        return {}

    matched = {}
    for index, group in enumerate(res.groups()):
        matched[groups[index]] = group

    return matched


def test_parse():
    regex = r".*\[([x\s])\] \(([^:}]+):?([^}]+)?\){([^\(\)]+)}: (.*)"
    matched = parse(
        "- [ ] (t1:t2,t3){1}: do someting",
        regex,
        ["status", "id", "dependencies", "tags", "content"],
    )
    print(matched)


# ~ find
def find(
    path: str,
    rg_pattern: str,
    parse_pattern: str,
    groups: List[str],
    concurrency: int = 10,
):
    matched = rg(path, rg_pattern)
    if len(matched) == 0:
        return []

    def do_parse(line):
        res = parse(line["text"], parse_pattern, groups)
        if len(res.keys()) == 0:
            return None

        return {**res, "path": line["path"], "lnum": line["lnum"]}

    with concurrent.futures.ThreadPoolExecutor(max_workers=concurrency) as executor:
        results = executor.map(do_parse, matched)
        return list(results)


def test_find():
    dir = os.path.join(os.path.dirname(__file__), "test")
    rg_pattern = r"\[.*\] \(.*\)\{.*\}: .*"
    parse_pattern = r".*\[([x\s])\] \(([^:}]+):?([^}]+)?\){([^\(\)]+)}: (.*)"
    groups = ["status", "id", "dependencies", "tags", "content"]
    matched = find(dir, rg_pattern, parse_pattern, groups)
    print(json.dumps(matched))


# ~ main
if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: python find.py dir rg_pattern parse_pattern groups")
        exit(1)

    path = sys.argv[1]
    rg_pattern = sys.argv[2]
    parse_pattern = sys.argv[3]
    groups = sys.argv[4].split(",")
    matched = find(path, rg_pattern, parse_pattern, groups)
    print(json.dumps(matched))
