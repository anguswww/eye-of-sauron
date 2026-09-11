# Eye of Sauron

An Intrusion Detection System (IDS) developed for a university project.

This guide gets every team member running the same safe, reproducible virtual
lab. You do not need to create or configure the virtual machines manually.
Vagrant reads the files in `lab/` and does that work for you.

## Repository layout

```text
eye-of-sauron/
├── lab/                 Virtual lab only
│   ├── Vagrantfile      VM, network, and resource definitions
│   ├── provision/       Software installed inside each VM
│   └── captures/        Local packet captures (not committed to Git)
├── src/                 Future IDS application code
├── tests/               Future automated tests
└── README.md            Project and setup instructions
```

Keeping infrastructure in `lab/`, application code in `src/`, and tests in
`tests/` is a common project layout. The whole repository is mounted at
`/workspace` inside every VM, so code placed in `src/` is immediately available
inside the lab.

## Lab design

```text
Kali Linux attacker       Ubuntu IDS/router               Ubuntu Desktop target
192.168.56.10  ------  192.168.56.30 | 192.168.57.30  ------  192.168.57.20
```

The IDS sits between two private VM networks, so all attacker-to-target traffic
crosses the IDS. Each VM also has a Vagrant-managed NAT adapter used only to
provision the machine, connect over SSH, and download packages. The lab uses
AMD64 guests and is supported only on x86-64 Windows and Linux hosts.

## First-time setup

Complete these steps once on each team member's computer.

### 1. Check the computer

You need:

- An x86-64 Windows or Linux computer with hardware virtualization enabled
- At least 12 GB system RAM; 16 GB is preferable
- At least 40 GB free disk space
- Administrator access for installing VMware Workstation and the VMware Utility

The running lab is allocated 8 GB RAM across its three VMs.

### 2. Install VMware

Install the current x86-64 version of
[VMware Workstation Pro](https://support.broadcom.com/) for Windows or Linux.
A free Broadcom account may be required for the download.

### 3. Install Vagrant

Download and install Vagrant from the
[official HashiCorp installation page](https://developer.hashicorp.com/vagrant/install).
Restart the terminal after installation, then check it:

```bash
vagrant --version
```

The command should print Vagrant 2.4 or later.

### 4. Install the Vagrant VMware plugin

Run:

```bash
vagrant plugin install vagrant-vmware-desktop
vagrant plugin list
```

The list should include `vagrant-vmware-desktop`. The plugin is free and does
not require a licence.

### 5. Install the Vagrant VMware Utility

The plugin also requires a separate background service called the Vagrant
VMware Utility. This is different from Vagrant itself. The Linux package-manager
commands currently shown on HashiCorp's VMware Utility download page install
the `vagrant` package, not the utility; do not repeat those commands for this
step.

On Ubuntu, Kubuntu, or Debian, download and install the AMD64 utility package
directly from the [official HashiCorp release](https://releases.hashicorp.com/vagrant-vmware-utility/1.0.24/).
Install `net-tools` on the host computer at the same time:

```bash
cd /tmp
wget https://releases.hashicorp.com/vagrant-vmware-utility/1.0.24/vagrant-vmware-utility_1.0.24-1_amd64.deb
sudo apt install ./vagrant-vmware-utility_1.0.24-1_amd64.deb net-tools
sudo systemctl enable --now vagrant-vmware-utility
```

The host installation of `net-tools` supplies `netstat`, which the VMware
provider uses to check for host-network address collisions before creating
private networks. Installing it inside one of the lab VMs will not satisfy this
requirement.

On Windows, download
`vagrant-vmware-utility_1.0.24_windows_amd64.msi` from the same official release
page and run the installer as an administrator. The installer creates and
starts the `vagrant-vmware-utility` Windows service.

The commands in this guide pin utility version 1.0.24 so that every team member
installs the same release. The general
[VMware Utility documentation](https://developer.hashicorp.com/vagrant/docs/providers/vmware/vagrant-vmware-utility)
describes manual installation and service recovery if the package installer
cannot be used.

On Linux, verify that the service is listening:

```bash
systemctl is-active vagrant-vmware-utility
nc -z 127.0.0.1 9922 && echo "VMware Utility is running"
```

On Windows PowerShell, verify it with:

```powershell
Get-Service vagrant-vmware-utility
Test-NetConnection 127.0.0.1 -Port 9922
```

The service should show as running or active, and the port check should report
`TcpTestSucceeded : True` on Windows.

### 6. Install Wireshark

Install [Wireshark](https://www.wireshark.org/download.html) on the host
computer. The IDS VM records packet captures, while the host Wireshark app
provides the easiest way to inspect them. The default installer options are
suitable for this lab.

### 7. Get the repository

Clone the repository using the URL supplied by the team, then enter the lab
directory:

```bash
git clone https://github.com/anguswww/eye-of-sauron.git
cd eye-of-sauron/lab
```

If the repository is already cloned, pull the latest version instead:

```bash
git pull
cd lab
```

### 8. Create the lab

From the `eye-of-sauron/lab` directory, run:

```bash
vagrant up --provider=vmware_desktop
```

The first run downloads two pinned AMD64 base images: Kali Linux for the
attacker and Ubuntu Desktop 24.04 LTS for both the IDS and target. It is
finished when Vagrant returns to the command prompt without an error. Later
starts will be much faster. The lab identifies the installed VMware product as
Workstation Pro so the provider can use supported Workstation commands and
space-efficient linked clones.

Vagrant opens all three desktops in VMware Workstation with the names
`Eye of Sauron - attacker`, `Eye of Sauron - ids`, and
`Eye of Sauron - target`. Continue to start, stop, and delete them using
Vagrant so its recorded state remains synchronized with VMware.

The attacker is a Kali Linux VM; the IDS and target are Ubuntu Desktop 24.04
LTS VMs. Their desktop environments are part of the downloaded images rather
than installed by a setup script. Sign in at any VMware console with username
`vagrant` and password `vagrant`. The IDS desktop includes the graphical
Wireshark application after provisioning, while the target hosts the lab test
services.

Do not close the terminal or put the computer to sleep during the first setup.

### 9. Confirm that everything works

Check that all three VMs are running:

```bash
vagrant status
```

The `attacker`, `ids`, and `target` machines should each show `running`.
Then send safe test traffic from the attacker to the target:

```bash
vagrant ssh attacker -c 'ping -c 2 192.168.57.20'
vagrant ssh attacker -c 'curl http://192.168.57.20/'
```

The second command should return a page containing `IDS Lab Target`.

## Capture a test with the IDS

Open two terminals and change to `eye-of-sauron/lab` in both.

In terminal 1, start capturing traffic:

```bash
vagrant ssh ids -c 'sudo capture-lab /workspace/lab/captures/test-traffic.pcap'
```

Leave it running. In terminal 2, generate a known TCP scan:

```bash
vagrant ssh attacker -c 'nmap -sT -Pn 192.168.57.20'
```

Return to terminal 1 and press `Ctrl-C`. The capture is now available at
`lab/captures/test-traffic.pcap` on the host and can be opened in Wireshark.
PCAP files are intentionally excluded from Git because they can be large and
may contain sensitive network data.

## Everyday commands

Run all Vagrant commands from `eye-of-sauron/lab`.

| Task | Command |
|---|---|
| Show VM status | `vagrant status` |
| Start all VMs | `vagrant up --provider=vmware_desktop` |
| Stop all VMs safely | `vagrant halt` |
| Connect to the IDS | `vagrant ssh ids` |
| Connect to the attacker | `vagrant ssh attacker` |
| Connect to the target | `vagrant ssh target` |
| Re-run setup scripts | `vagrant provision` |

When finished for the day, use `vagrant halt`. This preserves the VMs and makes
the next startup quick. Avoid closing the VMware console windows directly,
because Workstation may suspend the VMs instead of shutting them down through
Vagrant.

## Where the VMs are stored

Vagrant stores this lab's generated VMware clones inside:

```text
eye-of-sauron/lab/.vagrant/
```

That directory contains the virtual disks and machine metadata. It is local to
each team member and is ignored by Git. Deleting it manually can orphan Vagrant
state, so use `vagrant destroy` when removing the lab.

Vagrant also caches the downloaded base boxes outside the repository:

```text
~/.vagrant.d/boxes/
```

The cache is shared by all Vagrant projects belonging to that user. It is not
inside the Git repository and does not need a `.gitignore` rule. It can be
inspected with `vagrant box list` and cleaned deliberately with
`vagrant box remove BOX_NAME` when disk space is needed.

The repository `.gitignore` excludes `.vagrant/`, VMware disks and exports,
and PCAP files. Team members should commit the `Vagrantfile` and provisioning
scripts, but never the generated VM files themselves.

## Reset or remove the lab

If the lab becomes broken, recreate it with:

```bash
vagrant destroy
vagrant up --provider=vmware_desktop
```

`vagrant destroy` permanently deletes all three local lab VMs and anything
saved only inside them. It does not delete this Git repository or files saved
under `/workspace`. Vagrant asks for confirmation before deleting each VM.

## Troubleshooting

### Vagrant says that no provider is available

Confirm that VMware Workstation is installed and that the plugin appears in:

```bash
vagrant plugin list
```

### The lab reports an unsupported host

The lab intentionally accepts only x86-64 Windows and Linux hosts. Use a
supported team computer rather than changing the guest architecture or
provider.

### Vagrant cannot connect to the VMware Utility

Reinstall the Utility from the
[official download page](https://developer.hashicorp.com/vagrant/install/vmware),
then restart the computer if the service still does not start.

### A command says that no Vagrantfile exists

Change into the lab directory first:

```bash
cd eye-of-sauron/lab
```

### Setup was interrupted

Run the start command again. Vagrant normally continues from the existing
state:

```bash
vagrant up --provider=vmware_desktop
```

### VMware reports `File not found: disk-000001.vmdk`

This can happen if the host ran out of disk space while VMware was creating or
suspending a VM. Click **Cancel** in VMware; do not browse for an unrelated
virtual disk. Free enough host disk space, then replace only the affected VM:

```bash
vagrant destroy -f VM_NAME
vagrant up VM_NAME --provider=vmware_desktop
```

Replace `VM_NAME` with `attacker`, `ids`, or `target`. This deletes data stored
only inside that VM, but does not delete the repository or `/workspace` files.
Check available Linux host space with `df -h`. On Windows, check the drive
containing the repository in File Explorer. Keep at least 40 GB free before the
first build because base-box downloads and temporary clone files can briefly
require more space than the finished lab.

### `vmrun snapshot` reports `The operation is not supported`

Current VMware Workstation is the full Pro product when used under its free
licence. However, the Vagrant VMware provider can misidentify that licence as
legacy VMware Player and invoke `vmrun -T player`, where snapshots and some VM
control operations are unavailable. Pull the latest repository changes; the
lab corrects this detection and makes the provider use Workstation mode:

```bash
git pull
cd lab
vagrant up --provider=vmware_desktop
```

Do not add a paid licence key or edit the VMware Utility service configuration.
The Vagrantfile setting identifies the already-installed free Workstation Pro
product; it does not install or bypass a VMware licence.

### Changes to provisioning are not appearing

Pull the latest repository changes and re-run provisioning:

```bash
git pull
vagrant provision
```

### `/workspace` reports an input/output error

This usually means VMware's HGFS shared-folder mount became stale. From the
`lab/` directory, refresh the affected machines:

```bash
vagrant reload attacker target --provision
```

Then verify the repository mount and Git metadata:

```bash
vagrant ssh attacker -c 'git -C /workspace status'
vagrant ssh target -c 'git -C /workspace status'
vagrant ssh ids -c 'git -C /workspace status'
```

## Safety rules

- Run scanning and attack tools only against the private lab addresses listed
  in this README.
- Never bridge a lab network adapter to a physical, university, work, or home
  network.
- Never commit packet captures, credentials, secrets, or VM images to Git.
- Take snapshots or commit source changes before risky experiments.
