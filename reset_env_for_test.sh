NAME=cisco-nxosv
OWNER=nobody

# remove the modified disk image
if [ -f ./files/${NAME}.qcow2 ]; then
    rm ./files/${NAME}.qcow2
    printf "${NAME}.qcow2 deleted.\n"
fi
# remove the vagrant box package artifact
if [ -f ./${NAME}.box ]; then
    rm ./${NAME}.box
    printf "${NAME}.box deleted.\n"
fi
# copy a "fresh" disk image to the libvirt/images dir
sudo cp ${HOME}/Downloads/${NAME}.qcow2 /var/lib/libvirt/images/${NAME}.qcow2
if [ $? -eq 0 ]; then
    printf "${NAME}.qcow2 copied successfully to /var/lib/libvirt/images.\n"
fi
# set owner and perm on disk image
sudo chown ${OWNER}:kvm /var/lib/libvirt/images/${NAME}.qcow2
if [ $? -eq 0 ]; then
    printf "Owner changed successfully.\n"
fi
sudo chmod u+x /var/lib/libvirt/images/${NAME}.qcow2
if [ $? -eq 0 ]; then
    printf "Permissions changed successfully.\n"
fi
