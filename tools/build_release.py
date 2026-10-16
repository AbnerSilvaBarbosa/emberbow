#!/usr/bin/env python3
"""Export the Windows client and the Linux dedicated server, then package them."""
import argparse
import os
import pathlib
import subprocess
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
BUILD = ROOT / 'builds'
VERSION = '0.2.0'


def package(target, files):
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for source, name in files:
            archive.write(source, name)
    print(target.name, target.stat().st_size, 'bytes')


def licenses():
    folder = ROOT / 'assets' / 'licenses'
    return [(path, 'licenses/' + path.name) for path in sorted(folder.iterdir()) if path.is_file()]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN', 'godot'))
    parser.add_argument('--package-only', action='store_true')
    args = parser.parse_args()
    BUILD.mkdir(exist_ok=True)
    if not args.package_only:
        for preset in ['Windows', 'Linux Server']:
            subprocess.run([args.godot, '--headless', '--path', str(ROOT), '--export-release', preset], check=True)
    package(BUILD / ('Emberbow-Windows-%s.zip' % VERSION),
            [(BUILD / 'windows/Emberbow.exe', 'Emberbow.exe'), (ROOT / 'README.md', 'README.md')] + licenses())
    package(BUILD / ('Emberbow-Server-Linux-%s.zip' % VERSION),
            [(BUILD / 'linux/emberbow-server', 'emberbow-server'),
             (ROOT / 'server/emberbow.service', 'emberbow.service'),
             (ROOT / 'docs/SERVER.md', 'SERVER.md')] + licenses())
    sources = [(ROOT / name, name) for name in ['project.godot', 'scenes/main.tscn', 'export_presets.cfg', '.gitignore', 'Jogar.command', 'README.md', 'DESIGN.md', 'PRODUCT.md']]
    sources.extend((path, path.name) for path in (ROOT / 'docs').glob('*.md'))
    allowed = {'.gd', '.uid', '.png', '.json', '.md', '.py', '.service', '.wav', '.ttf', '.txt'}
    for folder in ['scripts', 'assets', 'audio', 'server', 'tests', 'tools']:
        for path in (ROOT / folder).rglob('*'):
            if path.is_file() and path.suffix in allowed and '__pycache__' not in path.parts:
                sources.append((path, str(path.relative_to(ROOT))))
    package(BUILD / ('Emberbow-Source-%s.zip' % VERSION), sources)


if __name__ == '__main__':
    main()
