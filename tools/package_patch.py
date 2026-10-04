"""Package only task changes; omit generated Godot imports and build artifacts."""
import subprocess
import sys
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
changed = subprocess.check_output(
    ['git', 'diff', '--name-only', '-z'], cwd=root
).decode().split('\0')
new = subprocess.check_output(
    ['git', 'ls-files', '--others', '--exclude-standard', '-z'], cwd=root
).decode().split('\0')
paths = sorted(set(filter(None, changed + new)))
with zipfile.ZipFile(sys.argv[1], 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    for name in paths:
        path = root / name
        if path.is_file():
            archive.write(path, name)
    assert archive.testzip() is None
print(f'{len(paths)} files: {sys.argv[1]}')
