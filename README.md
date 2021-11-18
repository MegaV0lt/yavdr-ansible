# yavdr-ansible
ansible playbooks for yaVDR

## What can yavdr-ansible do for me?
[Ansible](https://docs.ansible.com/ansible/latest/index.html) is an automation tool which can be used to configure systems and deploy software.
yavdr-ansible uses Ansible to set up a yaVDR System on top of an Ubuntu 20.04 Server installation (see below for details) and allows the user to fully customize the installation - have a look at the Ansible documentation if you want to learn how it works.

Please note that this is still work in progress and several features of yaVDR 0.6 haven't been implemented (yet).

## System Requirements and Compatiblity Notes
- RTC must be set to UTC in order for vdr-addon-acpiwakeup to work properly
- 32 Bit Installations on x86 systemd are only possible up to Ubuntu 18.04 focal or on Raspberry Pi 2 and 3 (armv7h)
- You need an IGP/GPU with support for VDPAU or VAAPI if you want to use software output plugins for VDR like softhddevice or vaapidevice
- xineliboutput/vdr-sxfe works with software rendering, too
- Can be used in a VirtualBox VM

## Usage:

Set up a Ubuntu Server 20.04.x Installation and install `openssh-server`.

On Ubuntu Server for Raspberry PI 2 and 3 it is recommended to set the timezone-information and generate and choose the wanted locale (e.g. `de_DE.UTF-8` for german language), so the vdr can use this information:
```shell
sudo dpkg-reconfigure tzdata
sudo dpkg-reconfigure locales
```

You can expand the root partition to use the free space on the sd-card as shown in https://wiki.ubuntu.com/ARM/RaspberryPi#Root_resize

NOTE: Since there is no alternative server installer for Ubuntu 20.04 anymore and the new ubiquity installer has to be used, the playbook needs to deconfigure and uninstall the `cloud-init` package - depending on the drivers used you might need to reboot the pc and run the playbook again so the xorg autodetection can function properly.


### Download yavdr-ansible
NOTE: It is recommended to use a SSH connection to run the playbook, especially if a nvidia card is used (in order to change from the nouveau to the nvidia driver the local console output needs to be disabled temporarily).

NOTE: The install script uses [mitogen for ansible](https://networkgenomics.com/ansible/) to speed up the playbook execution. The playbook directory must be readable by all users on the system, so don't put it in a directory under `/root/` or other directories with access restrictions.

Run the following commands to download the current version of yavdr-ansible:
```
sudo apt-get install git
git clone -b focal https://github.com/yavdr/yavdr-ansible
cd yavdr-ansible
```

### Customizing the Playbooks and Variables
You can choose the roles run by the playbooks `yavdr07.yml` or ` yavdr07-headless.yml`.

If you want to customize the variables in [group_vars/all](group_vars/all), copy the file to `host_vars/localhost` before changing it. This way you can change the PPAs used and choose which extra vdr plugins and packages should be installed by default.

### Run the Playbook
If you want a system with Xorg output run:
```shell
sudo -H ./install-yavdr.sh
```
NOTE: on systems with a nvidia card unloading the noveau driver after installing the proprietary nvidia driver can fail (in this case ansible throws an error). If this happens please reboot your system to allow the nvidia driver to be loaded and run the install script again.

If you want a headless vdr server run:
```shell
sudo -H ./install-yavdr-headless.sh
```

If you want to set up yavdr on a Raspberry Pi 2 or 3, run:
```shell
sudo -H ./install-yavdr-rpi.sh
```
On the Raspberry Pi a reboot is required to change the memory split and make the hardware decoder keys work. The Playbook will prompt you to do so.
## First Steps after the installation:

### Wait for local dvb adapters

The yaVDR VDR Package provides a systemd service `wait-for-dvb@.service` which allows to delay the start of vdr until all given locally connected dvb adapters have been initalized - e.g. to wait for `/dev/dvb/adapter0 .. /dev/dvb/adapter3`you can enable the required instances of this service like this:
```shell
systemctl enable wait-for-dvb@{0..3}.service
```
Please remember to adapt the enabled service instances if you change your configuration.

You can set the list of tuners to be waited for by changing the variable `wait_for_dvb_devices` for the playbook, so the instances of `wait-for-dvb@.service` will be enabled automatically. Please note that the playbook will deactivate all instances from 0 to `max_num_dvb_devices` (defaults to `16`) which are not enabled in the variable `wait_for_dvb_devices`.

This should work foll all DVB adaptors for which udev events are generated. Note that devices with userspace drivers (e.g. by Sundtek) won't emit such events.

### Add a /var/lib/vdr/channels.conf

You can use the wirbelscan-Plugin, w_scan, t2scan (especially useful for DVB-T2) or ready-to-use channellists from http://channelpedia.yavdr.com/gen/

Important: vdr.service must be stopped if you want to edit VDR configuration files: `sudo stop vdr.service`

### Rescan displays
If you change the connected displays you may need to update the display configuration. This can be achived by running the `yavdr-xorg` role:
```shell
sudo -H ansible-playbook yavdr07.yml -b -i 'localhost_inventory' --connection=local --tags="yavdr-xorg"
```

### running single roles without a custom playbook
You can choose to (re-)run single roles included in a playbook by including their name in the `--tags` argument (see example above for rescanning displays with `yavdr-xorg`).
