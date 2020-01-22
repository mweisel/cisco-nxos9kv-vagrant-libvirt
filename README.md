A procedure for creating a Cisco Nexus 9000v Vagrant box for the [libvirt](https://libvirt.org) provider.

## Prerequisites

  * [Git](https://git-scm.com)
  * [Python](https://www.python.org)
  * [Ansible](https://docs.ansible.com/ansible/latest/index.html)
  * [libvirt](https://libvirt.org) with client tools
  * [QEMU](https://www.qemu.org)
  * [Expect](https://en.wikipedia.org/wiki/Expect)
  * [Telnet](https://en.wikipedia.org/wiki/Telnet)
  * [Vagrant](https://www.vagrantup.com)
  * [vagrant-libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt)

## Steps

0. Verify the prerequisite tools are installed.

```
which git python ansible libvirtd virsh qemu-system-x86_64 expect telnet vagrant
vagrant plugin list
```

1. Install the `ovmf` package.

> Arch Linux
```
sudo pacman -S ovmf
```

> Ubuntu 18.04
```
sudo apt install ovmf
```

2. Clone this GitHub repo and _cd_ into the directory.

```
git clone https://github.com/mweisel/cisco-nxos9kv-vagrant-libvirt
cd cisco-nxos9kv-vagrant-libvirt
```

3. Log in and download the Cisco Nexus 9000/3000 Virtual Switch for KVM disk image file from your [Cisco](https://www.cisco.com/c/en/us/support/switches/nexus-9000v-switch/model.html#~tab-downloads) account.

4. Copy (and rename) the disk image file to the `/var/lib/libvirt/images` directory.

```
sudo cp $HOME/Downloads/nexus9500v.9.3.3.qcow2 /var/lib/libvirt/images/cisco-nxosv.qcow2
```

5. Modify the file ownership and permissions. Note the owner will differ between Linux distributions.

> Arch Linux
```
sudo chown nobody:kvm /var/lib/libvirt/images/cisco-nxosv.qcow2
sudo chmod u+x /var/lib/libvirt/images/cisco-nxosv.qcow2
```

> Ubuntu 18.04
```
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/cisco-nxosv.qcow2
sudo chmod u+x /var/lib/libvirt/images/cisco-nxosv.qcow2
```

6. Get the the path to your OVMF firmware image and runtime variables template. 

> Arch Linux
```
pacman -Ql ovmf | grep 'fd$'
```

> Ubuntu 18.04
```
dpkg -L ovmf | grep -E 'OVMF_(CODE|VARS)\.fd'
```

7. Modify the OVMF paths in the `cisco-nxosv.xml` and `create_box.sh` files.

> Arch Linux
```
# cisco-nxosv.xml file
<loader readonly='yes' secure='no' type='rom'>/usr/share/ovmf/x64/OVMF_CODE.fd</loader>
<nvram template='/usr/share/ovmf/x64/OVMF_VARS.fd'/>

# create_box.sh file 
domain.loader = "/usr/share/ovmf/x64/OVMF_CODE.fd"
```

> Ubuntu 18.04
```
# cisco-nxosv.xml file
<loader readonly='yes' secure='no' type='rom'>/usr/share/OVMF/OVMF_CODE.fd</loader>
<nvram template='/usr/share/OVMF/OVMF_VARS.fd'/>

# create_box.sh file 
domain.loader = "/usr/share/OVMF/OVMF_CODE.fd"
```

8. Modify the `expect_script` and `nxos` variable values depending on the version.

| Disk image | Boot image | Expect script |
| :--- | :--- | :--- |
| nxosv-final.7.0.3.I7.7.qcow2 | 7.0.3.I7.7 | cisco_nxos_base_conf.exp |
| nxosv.9.2.4.qcow2 | 9.2.4 | cisco_nxos_base_conf.exp |
| nexus9300v.9.3.3.qcow2 | 9.3.3 | cisco_nexus9x00v_base_conf.exp |
| nexus9500v.9.3.3.qcow2 | 9.3.3 | cisco_nexus9x00v_base_conf.exp |

For example, if using the `nxosv-final.7.0.3.I7.7.qcow2` disk image:

```
# main.yml file
expect_script: cisco_nxos_base_conf.exp

# cisco_nxos_base_conf.exp file
set nxos "7.0.3.I7.7"
```

If using the `nexus9300v.9.3.3.qcow2` disk image:

```
# main.yml file
expect_script: cisco_nexus9x00v_base_conf.exp

# cisco_nexus9x00v_base_conf.exp file
set nxos "9.3.3"
```

9. Start the `vagrant-libvirt` network (if not already started).

```
virsh -c qemu:///system net-list
virsh -c qemu:///system net-start vagrant-libvirt
```

10. Run the Ansible playbook. 

```
ansible-playbook main.yml
```

11. Add the Vagrant box. 

```
vagrant box add --provider libvirt --name cisco-nexus9500v-9.3.3 ./cisco-nxosv.box
```

## Debug

To view the telnet session output for the `expect` task:

```
tail -f ~/nxosv-console.explog
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
