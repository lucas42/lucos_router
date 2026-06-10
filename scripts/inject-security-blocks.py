#!/usr/bin/env python3
"""
Injects domain-specific security location blocks into a generated nginx server config.

Usage: echo "<nginx config>" | inject-security-blocks.py <domain>

Reads nginx config from stdin, looks for block files in
/etc/nginx/domain-security-blocks/<domain>/*.conf, inserts any found blocks
immediately before the first "  location / {" line, then writes to stdout.

If no security block directory exists for the domain, the config is passed
through unchanged.
"""
import sys
import os

if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} <domain>", file=sys.stderr)
    sys.exit(1)

domain = sys.argv[1]
content = sys.stdin.read()
security_dir = f"/etc/nginx/domain-security-blocks/{domain}"

if os.path.isdir(security_dir):
    blocks = []
    for fname in sorted(os.listdir(security_dir)):
        if fname.endswith('.conf'):
            fpath = os.path.join(security_dir, fname)
            with open(fpath) as fh:
                blocks.append(fh.read().rstrip())
    if blocks:
        combined = '\n\n'.join(blocks)
        content = content.replace('  location / {', combined + '\n\n  location / {', 1)

print(content, end='')
