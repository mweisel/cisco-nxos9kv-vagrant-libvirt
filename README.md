# Cisco Nexus 9000v Vagrant box (libvirt)

A procedure for creating a Cisco Nexus 9000v Vagrant box for the [libvirt](https://libvirt.org) provider.

<a href="https://asciinema.org/a/306347?speed=8"><img src="https://asciinema.org/a/306347.svg" width="720"/></a>

## Prerequisites

  * [Git](https://git-scm.com)
  * [Python](https://www.python.org)
  * [Ansible](https://docs.ansible.com/ansible/latest/index.html) >= 2.7
  * [libvirt](https://libvirt.org) with client tools
  * [QEMU](https://www.qemu.org)
  * [Expect](https://en.wikipedia.org/wiki/Expect)
  * [Telnet](https://en.wikipedia.org/wiki/Telnet)
  * [Vagrant](https://www.vagrantup.com)
  * [vagrant-libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt)

## Steps

0\. Verify the prerequisite tools are installed.

<pre>
$ <b>which git python ansible libvirtd virsh qemu-system-x86_64 expect telnet vagrant</b>
</pre>

<pre>
$ <b>vagrant plugin list</b>
vagrant-libvirt (0.1.2, global)
</pre>

1\. Install the `ovmf` package.

> Arch Linux

<pre>
$ <b>sudo pacman -S edk2-ovmf</b>
</pre>

> Ubuntu 18.04

<pre>
$ <b>sudo apt install ovmf</b>
</pre>

2\. Clone this GitHub repo and _cd_ into the directory.

<pre>
$ <b>git clone https://github.com/mweisel/cisco-nxos9kv-vagrant-libvirt</b>
$ <b>cd cisco-nxos9kv-vagrant-libvirt</b>
</pre>

3\. Log in and download the Cisco Nexus 9000/3000 Virtual Switch for KVM disk image file from your [Cisco](https://www.cisco.com/c/en/us/support/switches/nexus-9000v-switch/model.html#~tab-downloads) account.

4\. Copy (and rename) the disk image file to the `/var/lib/libvirt/images` directory.

<pre>
$ <b>sudo cp $HOME/Downloads/nexus9500v.9.3.3.qcow2 /var/lib/libvirt/images/cisco-nxosv.qcow2</b>
</pre>

5\. Modify the file ownership and permissions. Note the owner may differ between Linux distributions.

> Arch Linux

<pre>
$ <b>sudo chown nobody:kvm /var/lib/libvirt/images/cisco-nxosv.qcow2</b>
$ <b>sudo chmod u+x /var/lib/libvirt/images/cisco-nxosv.qcow2</b>
</pre>

> Ubuntu 18.04

<pre>
$ <b>sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/cisco-nxosv.qcow2</b>
$ <b>sudo chmod u+x /var/lib/libvirt/images/cisco-nxosv.qcow2</b>
</pre>

6\. Get the path to your OVMF (x64) firmware image and runtime variables template.

> Arch Linux

<pre>
$ <b>pacman -Ql edk2-ovmf | grep -E 'x64/OVMF_(CODE|VARS)\.fd'</b>
</pre>

> Ubuntu 18.04

<pre>
$ <b>dpkg -L ovmf | grep -E 'OVMF_(CODE|VARS)\.fd'</b>
</pre>

7\. Modify the OVMF paths.

> Arch Linux

<pre>
$ <b>vim templates/cisco-nxosv.xml</b>
</pre>

<pre>
&lt;domain type='kvm'&gt;
  &lt;name&gt;cisco-nxosv&lt;/name&gt;
  &lt;memory unit='KiB'&gt;8388608&lt;/memory&gt;
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
    domain.loader = "<b>/usr/share/edk2-ovmf/x64/OVMF_CODE.fd</b>"
    domain.memory = 8192
    domain.disk_bus = "sata"
    domain.disk_device = "sda"
    domain.volume_cache = "unsafe"
    domain.nic_model_type = "e1000"
    domain.graphics_type = "none"
  end
...
</pre>

<br />

> Ubuntu 18.04

<pre>
$ <b>vim templates/cisco-nxosv.xml</b>
</pre>

<pre>
&lt;domain type='kvm'&gt;
  &lt;name&gt;cisco-nxosv&lt;/name&gt;
  &lt;memory unit='KiB'&gt;8388608&lt;/memory&gt;
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
    domain.loader = "<b>/usr/share/OVMF/OVMF_CODE.fd</b>"
    domain.memory = 8192
    domain.disk_bus = "sata"
    domain.disk_device = "sda"
    domain.volume_cache = "unsafe"
    domain.nic_model_type = "e1000"
    domain.graphics_type = "none"
  end
...
</pre>

8\. Modify the `expect_script` and `nxos` variable values.

Use the following as a guideline:

| Disk image | Boot image | Expect script |
| :--- | :--- | :--- |
| nxosv-final.7.0.3.I7.8.qcow2 | 7.0.3.I7.8 | cisco_nxos_base_conf.exp |
| nxosv.9.2.4.qcow2 | 9.2.4 | cisco_nxos_base_conf.exp |
| nexus9500v.9.3.3.qcow2 | 9.3.3 | cisco_nexus9x00v_base_conf.exp |
| nexus9300v.9.3.5.qcow2 | 9.3.5 | cisco_nexus9x00v_base_conf.exp |

<br />

> nxosv-final.7.0.3.I7.8.qcow2

<pre>
$ <b>vim main.yml</b>
</pre>

<pre>
...

  vars:
    - disk_image_name: cisco-nxosv.qcow2
    - domain_name: cisco-nxosv
    - expect_script: <b>cisco_nxos_base_conf.exp</b>

...
</pre>

<pre>
$ <b>vim files/cisco_nxos_base_conf.exp</b>
</pre>

<pre>
set timeout 360
set prompt "(>|#) $"
set nxos "<b>7.0.3.I7.8</b>"
log_file -noappend "~/nxosv-console.explog"

...
</pre>

<br />

> nexus9300v.9.3.5.qcow2

<pre>
$ <b>vim main.yml</b>
</pre>

<pre>
...

  vars:
    - disk_image_name: cisco-nxosv.qcow2
    - domain_name: cisco-nxosv
    - expect_script: <b>cisco_nexus9x00v_base_conf.exp</b>

...
</pre>

<pre>
$ <b>vim files/cisco_nexus9x00v_base_conf.exp</b>
</pre>

<pre>
set timeout 360
set prompt "(>|#) $"
set nxos "<b>9.3.5</b>"
log_file -noappend "~/nxosv-console.explog"

...
</pre>

9\. Start the `vagrant-libvirt` network (if not already started).

<pre>
$ <b>virsh -c qemu:///system net-list</b>
$ <b>virsh -c qemu:///system net-start vagrant-libvirt</b>
</pre>

10\. Run the Ansible playbook.

<pre>
$ <b>ansible-playbook main.yml</b>
</pre>

11\. Add the Vagrant box to the local inventory.

<pre>
$ <b>vagrant box add --provider libvirt --name cisco-nexus9500v-9.3.3 ./cisco-nxosv.box</b>
</pre>

## Debug

View the telnet session output for the `expect` task:

<pre>
$ <b>tail -f ~/nxosv-console.explog</b>
</pre>

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
