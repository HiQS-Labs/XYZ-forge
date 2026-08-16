import sys
import os
import json
import requests

if len(sys.argv) < 2:
    print("Usage: extract_artifacts.py <brief_path>")
    sys.exit(1)

brief_path = sys.argv[1]
with open(brief_path, "r") as f:
    brief_content = f.read()

with open(os.path.expanduser("~/secrets/xyz/qwen-token-plan.txt"), "r") as f:
    api_key = f.readline().strip()

system_prompt = """You are an expert at extracting file paths from GitHub issues.
Read the provided issue brief and identify the exact file paths that are expected to be modified.
Return ONLY a comma-separated list of the file paths, and absolutely nothing else.
If you are unsure, do your best to extract the core files mentioned in the "Scope" or body.
DO NOT wrap the response in backticks or markdown formatting.
Example output: utils/py/marathon_drive.py,README.md,phases/p1/RELAY.md
"""

url = "https://token-plan.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1/chat/completions"
headers = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json"
}

data = {
    "model": "qwen3.7-plus",
    "messages": [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": brief_content}
    ],
    "temperature": 0.0
}

response = requests.post(url, headers=headers, json=data)
response.raise_for_status()

result = response.json()
extracted = result["choices"][0]["message"]["content"].strip()
print(extracted)
