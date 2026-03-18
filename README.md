![Vagrant](https://img.shields.io/badge/vagrant%20-%231563FF.svg?&style=for-the-badge&logo=vagrant&logoColor=white)

# Cisco Nexus 9000v Switch Vagrant box

A procedure for creating a Cisco Nexus 9000v Switch Vagrant box for the [libvirt](https://libvirt.org) provider.

## Prerequisites

  - [Git](https://git-scm.com)
  - [uv](https://docs.astral.sh/uv)
  - [libvirt](https://libvirt.org) with client tools
  - [QEMU](https://www.qemu.org)
  - [Vagrant](https://developer.hashicorp.com/vagrant) >= 2.4.0
  - [vagrant-libvirt](https://vagrant-libvirt.github.io/vagrant-libvirt)
  - [Expect](https://en.wikipedia.org/wiki/Expect)
  - [Telnet](https://en.wikipedia.org/wiki/Telnet)

> Using [Install and configure a lab server with Arch Linux](https://marcstech.blog/archives/install-configure-lab-server-arch-linux) as a reference for the following steps.

## Steps

0\. Verify the prerequisite tools are installed.

```
which git uv libvirtd virsh qemu-system-x86_64 expect telnet vagrant
```

1\. Install the `edk2-ovmf` package.

```
sudo pacman -S edk2-ovmf
```

2\. Log in and download a [Cisco Nexus 9000/3000 Virtual Switch for KVM](https://software.cisco.com/download/home/286312239/type) **10.6(x)** disk image file.

3\. Copy (and rename) the disk image file to the `/var/lib/libvirt/images` directory.

// 9300v Lite 10.6(2)(F)

```
sudo cp nexus9300v64-lite.10.6.2.F.qcow2 /var/lib/libvirt/images/cisco-nxosv.qcow2
```

// 9300v 10.6(2)(F)

```
sudo cp nexus9300v64.10.6.2.F.qcow2 /var/lib/libvirt/images/cisco-nxosv.qcow2
```

// 9500 Lite 10.6(2)(F)

```
sudo cp nexus9500v64-lite.10.6.2.F.qcow2 /var/lib/libvirt/images/cisco-nxosv.qcow2
```

// 9500 10.6(2)(F)

```
sudo cp nexus9500v64.10.6.2.F.qcow2 /var/lib/libvirt/images/cisco-nxosv.qcow2
```

4\. Modify the file ownership.

> The owner and/or group will differ between Linux distributions.

```
sudo chown libvirt-qemu:libvirt-qemu /var/lib/libvirt/images/cisco-nxosv.qcow2
```

5\. Set the file as executable.

```
sudo chmod u+x /var/lib/libvirt/images/cisco-nxosv.qcow2
```

6\. Create the `boxes` directory.

```
mkdir -p ~/boxes
```

7\. Start the `default` network (if not already started).

```
virsh -c qemu:///system net-start default
```

8\. Clone this repo and `cd` into the directory.

```
git clone https://github.com/mweisel/cisco-nxos9kv-vagrant-libvirt && cd cisco-nxos9kv-vagrant-libvirt
```

9\. Get the path to the OVMF (x64) firmware image and runtime variables template.

```
pacman -Ql edk2-ovmf | grep -E 'x64/OVMF_(CODE|VARS)\.4m\.fd'
```

output:

```
edk2-ovmf /usr/share/edk2/x64/OVMF_CODE.4m.fd
edk2-ovmf /usr/share/edk2/x64/OVMF_VARS.4m.fd
```

10\. Modify/Verify the OVMF paths in the `create_box.sh` script file.

```
vim files/create_box.sh
```

<pre>
...

  config.vm.provider :libvirt do |domain|
    domain.cpus = 4
    domain.features = ['acpi']
    domain.loader = '<b>/usr/share/edk2/x64/OVMF_CODE.4m.fd</b>'
    domain.nvram = '<b>/usr/share/edk2/x64/OVMF_VARS.4m.fd</b>'
    domain.memory = 122288
    domain.disk_bus = 'sata'
    domain.disk_device = 'sda'
    domain.disk_driver :cache => 'none'
    domain.nic_model_type = 'e1000'
    domain.graphics_type = 'none'
  end
...
</pre>

11\. Modify/Verify the variable values in the `boot_image.exp` script file.

| Disk image | nxos | is_lite |
| :--- | :--- | :--- |
| nexus9300v64-<b>lite</b>.10.6.2.F.qcow2 | 10.6.2.F | <b>1</b> |
| nexus9300v64.10.6.2.F.qcow2 | 10.6.2.F | 0 |
| nexus9500v64-<b>lite</b>.10.6.2.F.qcow2 | 10.6.2.F | <b>1</b> |
| nexus9500v64.10.6.2.F.qcow2 | 10.6.2.F | 0 |

<br />

```
vim files/boot_image.exp
```

// 9300v64 **Lite** or 9500v64 **Lite** 10.6(2)(F)

<pre>
set nxos "<b>10.6.2.F</b>"
set is_lite <b>1</b>
</pre>

// 9300v64 or 9500v64 10.6(2)(F)

<pre>
set nxos "<b>10.6.2.F</b>"
set is_lite <b>0</b>
</pre>

12\. Create a Python virtual environment for Ansible.

```
uv sync
```

13\. Run the Ansible playbook.

```
uv run ansible-playbook main.yml
```

14\. Copy (and rename) the Vagrant box artifact to the `boxes` directory.

// 9300v64 Lite 10.6(2)(F)

```
cp cisco-nxosv.box $HOME/boxes/cisco-nexus9300v-10.6.2.F-lite.box
```

// 9300v64 10.6(2)(F)

```
cp cisco-nxosv.box $HOME/boxes/cisco-nexus9300v-10.6.2.F.box
```

// 9500v64 Lite 10.6(2)(F)

```
cp cisco-nxosv.box $HOME/boxes/cisco-nexus9500v-10.6.2.F-lite.box
```

// 9500v64 10.6(2)(F)

```
cp cisco-nxosv.box $HOME/boxes/cisco-nexus9500v-10.6.2.F.box
```

15\. Copy the box metadata file to the `boxes` directory.

// 9300v64 Lite 10.6(2)(F)

```
cp ./files/cisco-nexus9300v-lite.json $HOME/boxes/
```

// 9300v64 10.6(2)(F)

```
cp ./files/cisco-nexus9300v.json $HOME/boxes/
```

// 9500v64 Lite 10.6(2)(F)

```
cp ./files/cisco-nexus9500v-lite.json $HOME/boxes/
```

// 9500v64 10.6(2)(F)

```
cp ./files/cisco-nexus9500v.json $HOME/boxes/
```

16\. Change the current working directory to `boxes`.

```
cd $HOME/boxes
```

17\. Substitute the `HOME` placeholder string in the box metadata file.

// 9300v64 Lite 10.6(2)(F)

<pre>
$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9300v-lite.json</b>
"url": "file://<b>HOME</b>/boxes/cisco-nexus9300v-VER-lite.box"

$ <b>sed -i "s|HOME|${HOME}|" cisco-nexus9300v-lite.json</b>

$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9300v-lite.json</b>
"url": "file://<b>/home/marc</b>/boxes/cisco-nexus9300v-VER-lite.box"
</pre>

// 9300v64 10.6(2)(F)

<pre>
$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9300v.json</b>
"url": "file://<b>HOME</b>/boxes/cisco-nexus9300v-VER.box"

$ <b>sed -i "s|HOME|${HOME}|" cisco-nexus9300v.json</b>

$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9300v.json</b>
"url": "file://<b>/home/marc</b>/boxes/cisco-nexus9300v-VER.box"
</pre>

// 9500v64 Lite 10.6(2)(F)

<pre>
$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9500v-lite.json</b>
"url": "file://<b>HOME</b>/boxes/cisco-nexus9500v-VER-lite.box"

$ <b>sed -i "s|HOME|${HOME}|" cisco-nexus9500v-lite.json</b>

$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9500v-lite.json</b>
"url": "file://<b>/home/marc</b>/boxes/cisco-nexus9500v-VER-lite.box"
</pre>

// 9500v64 10.6(2)(F)

<pre>
$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9500v.json</b>
"url": "file://<b>HOME</b>/boxes/cisco-nexus9500v-VER.box"

$ <b>sed -i "s|HOME|${HOME}|" cisco-nexus9500v.json</b>

$ <b>awk '/url/{gsub(/^ */,"");print}' cisco-nexus9500v.json</b>
"url": "file://<b>/home/marc</b>/boxes/cisco-nexus9500v-VER.box"
</pre>

18\. Also, substitute the `VER` placeholder string with the Cisco NX-OS version.

// 9300v64 Lite 10.6(2)(F)

<pre>
$ <b>awk '/VER/{gsub(/^ */,"");print}' cisco-nexus9300v-lite.json</b>
"version": "<b>VER</b>",
"url": "file:///home/marc/boxes/cisco-nexus9300v-<b>VER</b>-lite.box"

$ <b>sed -i 's/VER/10.6.2.F/g' cisco-nexus9300v-lite.json</b>

$ <b>awk '/\&lt;version\&gt;|url/{gsub(/^ */,"");print}' cisco-nexus9300v-lite.json</b>
"version": "<b>10.6.2.F</b>",
"url": "file:///home/marc/boxes/cisco-nexus9300v-<b>10.6.2.F</b>-lite.box"
</pre>

// 9300v64 10.6(2)(F)

<pre>
$ <b>awk '/VER/{gsub(/^ */,"");print}' cisco-nexus9300v.json</b>
"version": "<b>VER</b>",
"url": "file:///home/marc/boxes/cisco-nexus9300v-<b>VER</b>.box"

$ <b>sed -i 's/VER/10.6.2.F/g' cisco-nexus9300v.json</b>

$ <b>awk '/\&lt;version\&gt;|url/{gsub(/^ */,"");print}' cisco-nexus9300v.json</b>
"version": "<b>10.6.2.F</b>",
"url": "file:///home/marc/boxes/cisco-nexus9300v-<b>10.6.2.F</b>.box"
</pre>

// 9500v64 Lite 10.6(2)(F)

<pre>
$ <b>awk '/VER/{gsub(/^ */,"");print}' cisco-nexus9500v-lite.json</b>
"version": "<b>VER</b>",
"url": "file:///home/marc/boxes/cisco-nexus9500v-<b>VER</b>-lite.box"

$ <b>sed -i 's/VER/10.6.2.F/g' cisco-nexus9500v-lite.json</b>

$ <b>awk '/\&lt;version\&gt;|url/{gsub(/^ */,"");print}' cisco-nexus9500v-lite.json</b>
"version": "<b>10.6.2.F</b>",
"url": "file:///home/marc/boxes/cisco-nexus9500v-<b>10.6.2.F</b>-lite.box"
</pre>

// 9500v64 10.6(2)(F)

<pre>
$ <b>awk '/VER/{gsub(/^ */,"");print}' cisco-nexus9500v.json</b>
"version": "<b>VER</b>",
"url": "file:///home/marc/boxes/cisco-nexus9500v-<b>VER</b>.box"

$ <b>sed -i 's/VER/10.6.2.F/g' cisco-nexus9500v.json</b>

$ <b>awk '/\&lt;version\&gt;|url/{gsub(/^ */,"");print}' cisco-nexus9500v.json</b>
"version": "<b>10.6.2.F</b>",
"url": "file:///home/marc/boxes/cisco-nexus9500v-<b>10.6.2.F</b>.box"
</pre>

19\. Add the Vagrant box to the local inventory.

// 9300v64 Lite 10.6(2)(F)

```
vagrant box add cisco-nexus9300v-lite.json
```

// 9300v64 10.6(2)(F)

```
vagrant box add cisco-nexus9300v.json
```

// 9500v64 Lite 10.6(2)(F)

```
vagrant box add cisco-nexus9500v-lite.json
```

// 9500v64 10.6(2)(F)

```
vagrant box add cisco-nexus9500v.json
```

## Debug

View the Telnet session output for the `expect` task:

```
tail -f ~/nxosv-console.explog
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
