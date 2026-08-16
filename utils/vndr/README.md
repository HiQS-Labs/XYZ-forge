# `vndr` Tool

`vndr` is a generic tool designed to materialize a mini-utility into a target repository and register that installation in a machine-local registry (`~/.config/vndr/`). This allows you to vendor scripts and utilities per-repository without losing track of where they are installed, enabling a unified upgrade path (`vndr sync`).

## Usage

Run `vndr` commands from the **source repository** of your utility (where the `.vendor.json` file lives).

```bash
# Vendor the utility into a target repository
./vndr.sh install /path/to/target/repo

# List all known installations of this utility
./vndr.sh list

# Sync (upgrade) all known installations to the current source commit
./vndr.sh sync

# Delete a vendored installation and remove it from the registry
./vndr.sh delete /path/to/target/repo
```

## Configuration

Place a `.vendor.json` file in the root of your utility's repository.

### Example `.vendor.json`
```json
{
  "name": "arch-diagrammer",
  "description": "Code architecture diagraming tool",
  "target_dir_name": ".arch-diagrammer",
  "registry_key": "arch-diagrammer",
  "vendor_paths": [
    "bin/",
    "src/",
    "README.md"
  ],
  "version_command": "cat src/VERSION 2>/dev/null || echo 'unknown'"
}
```

### Fields:
- `name`: (Required) The name of your tool.
- `target_dir_name`: (Optional) The folder name that will be created in the target repo. Defaults to `.<name>`.
- `registry_key`: (Optional) Used for the registry file name (`~/.config/vndr/<registry_key>.tsv`). Defaults to `name`.
- `vendor_paths`: (Required) Array of relative paths (directories or files) to copy.
- `version_command`: (Optional) Shell command to execute to determine the utility's version string.
