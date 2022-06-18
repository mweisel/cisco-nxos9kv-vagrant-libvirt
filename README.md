<img alt="Vagrant" src="https://img.shields.io/badge/vagrant%20-%231563FF.svg?&style=for-the-badge&logo=vagrant&logoColor=white"/>

# Cisco Nexus 9000v Vagrant box

A procedure for creating a Cisco Nexus 9000v Vagrant box for the [libvirt](https://libvirt.org) provider.

## Prerequisites

  * [Git](https://git-scm.com)
  * [Python](https://www.python.org) >= 3.8
  * [Ansible](https://docs.ansible.com/ansible/latest/index.html) >= 2.11.0
  * [libvirt](https://libvirt.org) with client tools
  * [QEMU](https://www.qemu.org)
  * [Expect](https://en.wikipedia.org/wiki/Expect)
  * [Telnet](https://en.wikipedia.org/wiki/Telnet)
  * [Vagrant](https://www.vagrantup.com) >= 2.2.10, != 2.2.16
  * [vagrant-libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt)

## Steps

0\. Verify the prerequisite tools are installed.

<pre>
$ <b>which git python ansible libvirtd virsh qemu-system-x86_64 expect telnet vagrant</b>
$ <b>vagrant plugin list</b>
vagrant-libvirt (0.9.0, global)
</pre>

1\. Install the `ovmf` package.

> Ubuntu 18.04

<pre>
$ <b>sudo apt install ovmf</b>
</pre>

> Arch Linux

<pre>
$ <b>sudo pacman -S edk2-ovmf</b>
</pre>

2\. Log in and download the _Cisco Nexus 9000/3000 Virtual Switch for KVM_ disk image file from your [Cisco](https://www.cisco.com/c/en/us/support/switches/nexus-9000v-switch/model.html#~tab-downloads) account. Save the file to your `Downloads` directory.

3\. Copy (and rename) the disk image file to the `/var/lib/libvirt/images` directory. Use one of the following examples corresponding to the file version you downloaded:

> 7.0(3)I7(10)

<pre>
$ <b>sudo cp $HOME/Downloads/nxosv-final.7.0.3.I7.10.qcow2 /var/lib/libvirt/images/cisco-nxosv.qcow2</b>
</pre>

> 9300v 9.3(7)

<pre>
$ <b>sudo cp $HOME/Downloads/nexus9300v.9.3.7.qcow2 /var/lib/libvirt/images/cisco-nxosv.qcow2</b>
</pre>

> 9500v64 10.1(2)

<pre>
$ <b>sudo cp $HOME/Downloads/nexus9500v64.10.1.2.qcow2 /var/lib/libvirt/images/cisco-nxosv.qcow2</b>
</pre>

> 9300v64 10.2(3)(F) lite

<pre>
$ <b>sudo cp $HOME/Downloads/nexus9300v64-lite.10.2.3.F.qcow2 /var/lib/libvirt/images/cisco-nxosv.qcow2</b>
</pre>

4\. Modify the file ownership and permissions. Note the owner may differ between Linux distributions.

> Ubuntu 18.04

<pre>
$ <b>sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/cisco-nxosv.qcow2</b>
$ <b>sudo chmod u+x /var/lib/libvirt/images/cisco-nxosv.qcow2</b>
</pre>

> Arch Linux

<pre>
$ <b>sudo chown libvirt-qemu:libvirt-qemu /var/lib/libvirt/images/cisco-nxosv.qcow2</b>
$ <b>sudo chmod u+x /var/lib/libvirt/images/cisco-nxosv.qcow2</b>
</pre>

5\. Create the `boxes` directory.

<pre>
$ <b>mkdir -p $HOME/boxes</b>
</pre>

6\. Start the `vagrant-libvirt` network (if not already started).

<pre>
$ <b>virsh -c qemu:///system net-list</b>
$ <b>virsh -c qemu:///system net-start vagrant-libvirt</b>
</pre>

7\. Clone this GitHub repo and `cd` into the directory.

<pre>
$ <b>git clone https://github.com/mweisel/cisco-nxos9kv-vagrant-libvirt</b>
$ <b>cd cisco-nxos9kv-vagrant-libvirt</b>
</pre>

8\. Get the path to your OVMF (x64) firmware image and runtime variables template.

> Ubuntu 18.04

<pre>
$ <b>dpkg -L ovmf | grep -E 'OVMF_(CODE|VARS)\.fd'</b>
</pre>

> Arch Linux

<pre>
$ <b>pacman -Ql edk2-ovmf | grep -E 'x64/OVMF_(CODE|VARS)\.fd'</b>
</pre>

9\. Modify the OVMF paths.

> Ubuntu 18.04

<pre>
$ <b>vim files/cisco-nxosv.xml</b>
</pre>

<pre>
&lt;domain type='kvm'&gt;
  &lt;name&gt;cisco-nxosv&lt;/name&gt;
  &lt;memory unit='KiB'&gt;10485760&lt;/memory&gt;
  &lt;vcpu placement='static'&gt;2&lt;/vcpu&gt;
  &lt;os&gt;
    &lt;type arch='x86_64'&gt;hvm&lt;/type&gt;
    &lt;loader readonly='yes' secure='no' type='rom'&gt;<b>/usr/share/OVMF/OVMF_CODE.fd</b>&lt;/loader&gt;
    &lt;nvram template='<b>/usr/share/OVMF/OVMF_VARS.fd</b>'/&gt;
    &lt;boot dev='hd'/&gt;
  &lt;/os&gt;
...
</pre>

<pre>
$ <b>vim files/create_box.sh</b>
</pre>

<pre>
...

  config.vm.provider :libvirt do |domain|
    domain.cpus = 2
    domain.features = ['acpi']
    domain.loader = '<b>/usr/share/OVMF/OVMF_CODE.fd</b>'
    domain.memory = 8192
    domain.disk_bus = 'sata'
    domain.disk_device = 'sda'
    domain.disk_driver :cache => 'none'
    domain.nic_model_type = 'e1000'
    domain.graphics_type = 'none'
  end
...
</pre>

<br />

> Arch Linux

<pre>
$ <b>vim files/cisco-nxosv.xml</b>
</pre>

<pre>
&lt;domain type='kvm'&gt;
  &lt;name&gt;cisco-nxosv&lt;/name&gt;
  &lt;memory unit='KiB'&gt;10485760&lt;/memory&gt;
  &lt;vcpu placement='static'&gt;2&lt;/vcpu&gt;
  &lt;os&gt;
    &lt;type arch='x86_64'&gt;hvm&lt;/type&gt;
    &lt;loader readonly='yes' secure='no' type='rom'&gt;<b>/usr/share/edk2-ovmf/x64/OVMF_CODE.fd</b>&lt;/loader&gt;
    &lt;nvram template='<b>/usr/share/edk2-ovmf/x64/OVMF_VARS.fd</b>'/&gt;
    &lt;boot dev='hd'/&gt;
  &lt;/os&gt;
...
</pre>

<pre>
$ <b>vim files/create_box.sh</b>
</pre>

<pre>
...

  config.vm.provider :libvirt do |domain|
    domain.cpus = 2
    domain.features = ['acpi']
    domain.loader = '<b>/usr/share/edk2-ovmf/x64/OVMF_CODE.fd</b>'
    domain.memory = 8192
    domain.disk_bus = 'sata'
    domain.disk_device = 'sda'
    domain.disk_driver :cache => 'none'
    domain.nic_model_type = 'e1000'
    domain.graphics_type = 'none'
  end
...
</pre>

10\. Modify/Verify the variable values in the `boot_image.exp` script file. Use the following table and examples for guidance:

| Disk image | nxos | is_64bit | is_lite |
| :--- | :--- | :--- | :--- |
| nxosv-final.7.0.3.I7.10.qcow2 | 7.0.3.I7.10 | 0 | 0 |
| nexus9300v.9.3.7.qcow2 | 9.3.7 | 0 | 0 |
| nexus9500v<b>64</b>.10.1.2.qcow2 | 10.1.2 | 1 | 0 |
| nexus9300v<b>64</b>-<b>lite</b>.10.2.3.F.qcow2 | 10.2.3.F | 1 | 1 |

<br />

<pre>
$ <b>vim files/boot_image.exp</b>
</pre>

> 7.0(3)I7(10)

<pre>
set timeout 360
set prompt "(>|#) $"
set nxos "<b>7.0.3.I7.10</b>"
set is_64bit <b>0</b>
set is_lite <b>0</b>
log_file -noappend "~/nxosv-console.explog"

...
</pre>

> 9300v 9.3(7)

<pre>
set timeout 360
set prompt "(>|#) $"
set nxos "<b>9.3.7</b>"
set is_64bit <b>0</b>
set is_lite <b>0</b>
log_file -noappend "~/nxosv-console.explog"

...
</pre>

> 9500v64 10.1(2)

<pre>
set timeout 360
set prompt "(>|#) $"
set nxos "<b>10.1.2</b>"
set is_64bit <b>1</b>
set is_lite <b>0</b>
log_file -noappend "~/nxosv-console.explog"

...
</pre>

> 9300v64 10.2(3)(F) lite

<pre>
set timeout 360
set prompt "(>|#) $"
set nxos "<b>10.2.3.F</b>"
set is_64bit <b>1</b>
set is_lite <b>1</b>
log_file -noappend "~/nxosv-console.explog"

...
</pre>

11\. Run the Ansible playbook.

<pre>
$ <b>ansible-playbook main.yml</b>
</pre>

12\. Copy (and rename) the Vagrant box artifact to the `boxes` directory.

> 7.0(3)I7(10)

<pre>
$ <b>cp cisco-nxosv.box $HOME/boxes/cisco-nexus9000v-7.0.3.I7.10.box</b>
</pre>

> 9300v 9.3(7)

<pre>
$ <b>cp cisco-nxosv.box $HOME/boxes/cisco-nexus9300v-9.3.7.box</b>
</pre>

> 9500v64 10.1(2)

<pre>
$ <b>cp cisco-nxosv.box $HOME/boxes/cisco-nexus9500v-10.1.2.box</b>
</pre>

> 9300v64 10.2(3)(F) lite

<pre>
$ <b>cp cisco-nxosv.box $HOME/boxes/cisco-nexus9300v-10.2.3.F-lite.box</b>
</pre>

13\. Copy the box metadata file to the `boxes` directory.

> 7.0(3)I7(10)

<pre>
$ <b>cp ./files/cisco-nexus9000v.json $HOME/boxes/</b>
</pre>

> 9300v 9.3(7)

<pre>
$ <b>cp ./files/cisco-nexus9300v.json $HOME/boxes/</b>
</pre>

> 9500v64 10.1(2)

<pre>
$ <b>cp ./files/cisco-nexus9500v.json $HOME/boxes/</b>
</pre>

> 9300v64 10.2(3)(F) lite

<pre>
$ <b>cp ./files/cisco-nexus9300v-lite.json $HOME/boxes/</b>
</pre>

14\. Change the current working directory to `boxes`.

<pre>
$ <b>cd $HOME/boxes</b>
</pre>

15\. Substitute the `HOME` placeholder string in the box metadata file.

> 7.0(3)I7(10)

<pre>
$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9000v.json</b>
"url": "file://<b>HOME</b>/boxes/cisco-nexus9000v-VER.box"

$ <b>sed -i "s|HOME|${HOME}|" cisco-nexus9000v.json</b>

$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9000v.json</b>
"url": "file://<b>/home/marc</b>/boxes/cisco-nexus9000v-VER.box"
</pre>

> 9300v 9.3(7)

<pre>
$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9300v.json</b>
"url": "file://<b>HOME</b>/boxes/cisco-nexus9300v-VER.box"

$ <b>sed -i "s|HOME|${HOME}|" cisco-nexus9300v.json</b>

$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9300v.json</b>
"url": "file://<b>/home/marc</b>/boxes/cisco-nexus9300v-VER.box"
</pre>

> 9500v64 10.1(2)

<pre>
$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9500v.json</b>
"url": "file://<b>HOME</b>/boxes/cisco-nexus9500v-VER.box"

$ <b>sed -i "s|HOME|${HOME}|" cisco-nexus9500v.json</b>

$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9500v.json</b>
"url": "file://<b>/home/marc</b>/boxes/cisco-nexus9500v-VER.box"
</pre>

> 9300v64 10.2(3)(F) lite

<pre>
$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9300v-lite.json</b>
"url": "file://<b>HOME</b>/boxes/cisco-nexus9300v-VER-lite.box"

$ <b>sed -i "s|HOME|${HOME}|" cisco-nexus9300v-lite.json</b>

$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9300v-lite.json</b>
"url": "file://<b>/home/marc</b>/boxes/cisco-nexus9300v-VER-lite.box"
</pre>

16\. Also, substitute the `VER` placeholder string with the Cisco NX-OS version.

> 7.0(3)I7(10)

<pre>
$ <b>awk '/VER/{gsub(/^ */,"");print}' cisco-nexus9000v.json</b>
"version": "<b>VER</b>",
"url": "file:///home/marc/boxes/cisco-nexus9000v-<b>VER</b>.box"

$ <b>sed -i 's/VER/7.0.3.I7.10/g' cisco-nexus9000v.json</b>

$ <b>awk '/\&lt;version\&gt;|url/{gsub(/^ */,"");print}' cisco-nexus9000v.json</b>
"version": "<b>7.0.3.I7.10</b>",
"url": "file:///home/marc/boxes/cisco-nexus9000v-<b>7.0.3.I7.10</b>.box"
</pre>

> 9300v 9.3(7)

<pre>
$ <b>awk '/VER/{gsub(/^ */,"");print}' cisco-nexus9300v.json</b>
"version": "<b>VER</b>",
"url": "file:///home/marc/boxes/cisco-nexus9300v-<b>VER</b>.box"

$ <b>sed -i 's/VER/9.3.7/g' cisco-nexus9300v.json</b>

$ <b>awk '/\&lt;version\&gt;|url/{gsub(/^ */,"");print}' cisco-nexus9300v.json</b>
"version": "<b>9.3.7</b>",
"url": "file:///home/marc/boxes/cisco-nexus9300v-<b>9.3.7</b>.box"
</pre>

> 9500v64 10.1(2)

<pre>
$ <b>awk '/VER/{gsub(/^ */,"");print}' cisco-nexus9500v.json</b>
"version": "<b>VER</b>",
"url": "file:///home/marc/boxes/cisco-nexus9500v-<b>VER</b>.box"

$ <b>sed -i 's/VER/10.1.2/g' cisco-nexus9500v.json</b>

$ <b>awk '/\&lt;version\&gt;|url/{gsub(/^ */,"");print}' cisco-nexus9500v.json</b>
"version": "<b>10.1.2</b>",
"url": "file:///home/marc/boxes/cisco-nexus9500v-<b>10.1.2</b>.box"
</pre>

> 9300v64 10.2(3)(F) lite

<pre>
$ <b>awk '/VER/{gsub(/^ */,"");print}' cisco-nexus9300v-lite.json</b>
"version": "<b>VER</b>",
"url": "file:///home/marc/boxes/cisco-nexus9300v-<b>VER</b>-lite.box"

$ <b>sed -i 's/VER/10.2.3.F/g' cisco-nexus9300v-lite.json</b>

$ <b>awk '/\&lt;version\&gt;|url/{gsub(/^ */,"");print}' cisco-nexus9300v-lite.json</b>
"version": "<b>10.2.3.F</b>",
"url": "file:///home/marc/boxes/cisco-nexus9300v-<b>10.2.3.F</b>-lite.box"
</pre>

17\. Add the Vagrant box to the local inventory.

> 7.0(3)I7(10)

<pre>
$ <b>vagrant box add --box-version 7.0.3.I7.10 cisco-nexus9000v.json</b>
</pre>

> 9300v 9.3(7)

<pre>
$ <b>vagrant box add --box-version 9.3.7 cisco-nexus9300v.json</b>
</pre>

> 9500v64 10.1(2)

<pre>
$ <b>vagrant box add --box-version 10.1.2 cisco-nexus9500v.json</b>
</pre>

> 9300v64 10.2(3)(F) lite

<pre>
$ <b>vagrant box add --box-version 10.2.3.F cisco-nexus9300v-lite.json</b>
</pre>

## Debug

View the telnet session output for the `expect` task:

<pre>
$ <b>tail -f ~/nxosv-console.explog</b>
</pre>

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
