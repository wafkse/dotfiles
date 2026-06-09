#!/usr/bin/env bash

TARGET_VENDOR="${1:-NVIDIA}"

SYMLINK_NAME="discrete"
RULE_PATH="/etc/udev/rules.d/discrete-dev-path.rules"
PCI_GPU_ID=$(lspci -d ::03xx | grep "${TARGET_VENDOR}" | cut -f1 -d' ')
UDEV_RULE="$(cat <<EOF
KERNEL=="card*", \
KERNELS=="0000:$PCI_GPU_ID", \
SUBSYSTEM=="drm", \
SUBSYSTEMS=="pci", \
SYMLINK+="dri/$SYMLINK_NAME"
EOF
)"

echo "$UDEV_RULE" | sudo tee "$RULE_PATH"
