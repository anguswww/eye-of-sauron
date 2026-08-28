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
Ubuntu Desktop attacker   Ubuntu Desktop IDS/router       Ubuntu Server target
192.168.56.10  ------  192.168.56.30 | 192.168.57.30  ------  192.168.57.20
```

The IDS sits between two private VM networks, so all attacker-to-target traffic
crosses the IDS. Each VM also has a Vagrant-managed NAT adapter used only to
download packages during setup.

## First-time setup

Complete these steps once on each team member's computer.

### 1. Check the computer

You need:

- A 64-bit Windows, macOS, or Linux computer with virtualization enabled
- At least 12 GB system RAM; 16 GB is preferable
- At least 30 GB free disk space
- Administrator access for installing VMware and the VMware Utility

The running lab is allocated 7 GB RAM across its three VMs.

### 2. Install VMware

Install the current version of:

- **macOS:** [VMware Fusion Pro](https://support.broadcom.com/)
- **Windows or Linux:** [VMware Workstation Pro](https://support.broadcom.com/)

VMware Fusion and Workstation are free for personal, educational, and
commercial use. A free Broadcom account may be required for the download.

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

The plugin also requires a separate background service. Download the correct
installer for your operating system and processor from the
[current VMware Utility page](https://developer.hashicorp.com/vagrant/install/vmware),
then run the installer.

On macOS or Linux, verify that the service is listening:

```bash
nc -z 127.0.0.1 9922 && echo "VMware Utility is running"
```

On Windows PowerShell, verify it with:

```powershell
Test-NetConnection 127.0.0.1 -Port 9922
```

Look for `TcpTestSucceeded : True`.

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

The first run downloads two pinned Ubuntu 24.04 LTS base images: Ubuntu Desktop
for the attacker and IDS, and Ubuntu Server for the target. Both ARM64 and AMD64
VMware builds are available, and Vagrant automatically downloads the build that
matches each team member's computer. It is finished when Vagrant returns to the
command prompt without an error. Later starts will be much faster.

Vagrant opens each VM in VMware Fusion or Workstation with the names
`Eye of Sauron - attacker`, `Eye of Sauron - ids`, and
`Eye of Sauron - target`. Continue to start, stop, and delete them using
Vagrant so its recorded state remains synchronized with VMware.

The attacker and IDS are prebuilt Ubuntu Desktop 24.04 LTS machines; the desktop
is part of the downloaded image rather than installed by a setup script. Sign in
at their VMware consoles with username `vagrant` and password `vagrant`. The
target is intentionally an Ubuntu Server 24.04 LTS text console because it is
only used to host test services. The IDS desktop includes the graphical
Wireshark application after provisioning.

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
because Fusion may suspend the VMs instead of shutting them down through
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

Confirm that VMware is installed and that the plugin appears in:

```bash
vagrant plugin list
```

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
Check available macOS or Linux host space with `df -h`. On Windows, check the
drive containing the repository in File Explorer. Keep at least 30 GB free
before the first build because base-box downloads and temporary clone files can
briefly require more space than the finished lab.

### Changes to provisioning are not appearing

Pull the latest repository changes and re-run provisioning:

```bash
git pull
vagrant provision
```

## Safety rules

- Run scanning and attack tools only against the private lab addresses listed
  in this README.
- Never bridge a lab network adapter to a physical, university, work, or home
  network.
- Never commit packet captures, credentials, secrets, or VM images to Git.
- Take snapshots or commit source changes before risky experiments.
