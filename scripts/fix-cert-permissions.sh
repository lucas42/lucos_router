#!/bin/sh
# Fix permissions on private keys so non-root services can read them.
# Uses a dedicated group (certreaders, GID 1500) to grant group read access.
# Other containers that need cert access should create a group with GID 1500
# and run their process as a member of that group.
set -e

find /etc/letsencrypt -name "privkey*.pem" -exec chgrp certreaders {} \;
find /etc/letsencrypt -name "privkey*.pem" -exec chmod 640 {} \;

# Make archive directories traversable so non-root cert readers can follow symlinks
find /etc/letsencrypt/archive -type d -exec chmod o+rx {} \;

echo "Cert permissions updated: private keys are now readable by group certreaders (GID 1500)"
