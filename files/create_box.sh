#!/usr/bin/env bash
#set -xu

error() {
    local msg="${1}"
    echo "==> ERROR: ${msg}"
    exit 1
}

usage() {
    echo "Usage: ${0} IMAGE [BOX] [Vagrantfile.add]"
    echo
    echo "Package a qcow2 image into a vagrant-libvirt reusable box"
}

# Print the image's backing file
backing(){
    local img=${1}
    qemu-img info "$img" | grep 'backing file:' | cut -d ':' -f2
}

# Rebase the image
rebase(){
    local img=${1}
    qemu-img rebase -p -b "" "$img"
    [[ "$?" -ne 0 ]] && error "Error during rebase"
}

# Is absolute path
isabspath(){
    local path=${1}
    [[ "$path" =~ ^/.* ]]
}

if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 1
fi

IMG=$(readlink -e "$1")
[[ "$?" -ne 0 ]] && error "'$1': No such image"

IMG_DIR=$(dirname "$IMG")
IMG_BASENAME=$(basename "$IMG")

BOX=${2:-}
# If no box name is supplied infer one from image name
if [[ -z "$BOX" ]]; then
    BOX_NAME=${IMG_BASENAME%.*}
    BOX=$BOX_NAME.box
else
    BOX_NAME=$(basename "${BOX%.*}")
fi

[[ -f "$BOX" ]] && error "'$BOX': Already exists"

CWD=$(pwd)
TMP_DIR="$CWD/_tmp_package"
TMP_IMG="$TMP_DIR/box.img"

mkdir -p "$TMP_DIR"

[[ ! -r "$IMG" ]] && error "'$IMG': Permission denied"

if [ -n "$3" ] && [ -r "$3" ]; then
  VAGRANTFILE_ADD="$(cat $3)"
fi

# We move / copy (when the image has master) the image to the tempdir
# ensure that it's moved back / removed again
if [[ -n $(backing "$IMG") ]]; then
    echo "==> Image has backing image, copying image and rebasing ..."
    trap "rm -rf $TMP_DIR" EXIT
    cp "$IMG" "$TMP_IMG"
    rebase "$TMP_IMG"
else
    if fuser -s "$IMG"; then
        error "Image '$IMG_BASENAME' is used by another process"
    fi

    # move the image to get a speed-up and use less space on disk
    trap 'mv "$TMP_IMG" "$IMG"; rm -rf "$TMP_DIR"' EXIT
    mv "$IMG" "$TMP_IMG"
fi

cd "$TMP_DIR"

#Using the awk int function here to truncate the virtual image size to an
#integer since the fog-libvirt library does not seem to properly handle
#floating point.
IMG_SIZE=$(qemu-img info --output=json "$TMP_IMG" | awk '/virtual-size/{s=int($2)/(1024^3); print (s == int(s)) ? s : int(s)+1 }')

echo "{$IMG_SIZE}"

cat > metadata.json <<EOF
{
    "provider": "libvirt",
    "format": "qcow2",
    "virtual_size": ${IMG_SIZE}
}
EOF

cat > Vagrantfile <<EOF
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use Vagrant's default insecure key
  config.ssh.insert_key = false
  # Modify default shell behavior
  config.ssh.shell = "run bash"
  # Set timeout to 6 mins
  config.vm.boot_timeout = 360
  # Disable default host <-> guest synced folder
  config.vm.synced_folder ".", "/vagrant", disabled: true
  # Set guest OS type to disable autodetection
  config.vm.guest = :tinycore

  config.vm.provider :libvirt do |domain|
    domain.cpus = 2
    domain.features = ['acpi']
    domain.loader = "/usr/share/OVMF/OVMF_CODE.fd"
    domain.memory = 8192
    domain.disk_bus = "sata"
    domain.disk_device = "sda"
    domain.volume_cache = "unsafe"
    domain.nic_model_type = "e1000"
    domain.graphics_type = "none"
  end
end
EOF

echo "==> Creating box, tarring and gzipping"

if type pigz >/dev/null 2>/dev/null; then
  GZ="pigz"
else
  GZ="gzip"
fi
tar cv -S --totals ./metadata.json ./Vagrantfile ./box.img | $GZ -c > "$BOX"

# if box is in tmpdir move it to CWD before removing tmpdir
if ! isabspath "$BOX"; then
    mv "$BOX" "$CWD"
fi

echo "==> ${BOX} created"
echo "==> You can now add the box:"
echo "==>   'vagrant box add ${BOX} --name ${BOX_NAME}'"
