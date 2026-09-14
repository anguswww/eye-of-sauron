# Eye of Sauron

Eye of Sauron is a university prototype of a machine-learning intrusion
detection system (IDS). It will analyse network traffic using a trained model
and basic heuristic rules, then produce a classification or alert.

## Repository layout
```text
eye-of-sauron/
├── lab/
│   ├── Vagrantfile          VM and network definitions
│   ├── provision/           VM setup scripts
│   └── captures/            Local PCAP files. ignored by Git
├── src/
│   └── eye_of_sauron/       Installable IDS Python package
├── tests/                   Automated tests
├── .python-version          Project Python version
├── pyproject.toml           Dependencies and tool configuration
└── uv.lock                  Locked dependency versions
```

The repository is mounted at `/workspace` inside each Vagrant VM. Generated VM
state is stored in `lab/.vagrant/` and must not be committed or edited manually.

## Python development

The project requires Python 3.12 or later and uses
[`uv`](https://docs.astral.sh/uv/) for dependency and environment management.

Install `uv` on Linux or macOS:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

On Windows PowerShell:

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

From the repository root:

```bash
uv sync
uv run eye-of-sauron --version
uv run pytest
uv run ruff check .
```

`pytest` runs the tests under `tests/`. `ruff` checks Python code quality and
formatting. Add dependencies with `uv add PACKAGE`, or development-only tools
with `uv add --dev PACKAGE`. Commit `pyproject.toml` and `uv.lock`, but not the
generated `.venv/` directory.

## Model training

The model-training team does not really need this repository, as all training will take place in Google Colab. Trained model artefacts are to be handed off to the integration team.

## Data generation

The data-generation team does not need to use Vagrant. Any isolated Kali Linux
VM equivalent to the `kalilinux/rolling` box version pinned in the Vagrantfile
(`2026.2.0`) is suitable for developing traffic generators and test scenarios.
The complete Vagrant lab is only needed for end-to-end routing and IDS tests.

Traffic generators and scenario definitions should go in a top-level
`datagen/` directory. Generated files should remain separate and be ignored by
Git:

```text
datagen/                 Scripts and scenario definitions
data/raw/                Generated captures or source data
data/processed/          Model-ready data
data/manifests/          Labels and run metadata
```

Each run should record a stable ID, label, scenario version, timestamps, source,
target, and capture filename. Generate raw traffic first, then use the same
feature extractor as the live IDS. Keep designated test runs out of the
training set.

Traffic generation and security testing must only be performed in an
authorised, isolated environment.

## Integration lab

Most contributors do not need the complete lab. It is intended for packet
capture, routing, enforcement, and end-to-end testing.

```text
Kali attacker                Ubuntu IDS/router                Ubuntu target
192.168.56.10  ------  192.168.56.30 | 192.168.57.30  ------  192.168.57.20
```

The lab requires an x86-64 Windows or Linux host with hardware virtualisation,
VMware Workstation Pro, Vagrant 2.4 or later, the Vagrant VMware Desktop plugin,
and the separate Vagrant VMware Utility. Allow at least 12 GB RAM and 40 GB of
free storage.

Install the provider plugin:

```bash
vagrant plugin install vagrant-vmware-desktop
```

After installing the VMware Utility using HashiCorp's instructions, create the
lab from `eye-of-sauron/lab/`:

```bash
vagrant up --provider=vmware_desktop
```

Check the lab and test the private network path:

```bash
vagrant status
vagrant ssh attacker -c 'ping -c 2 192.168.57.20'
vagrant ssh attacker -c 'curl http://192.168.57.20/'
```

The HTTP response should contain `IDS Lab Target`.

### Capture test traffic

Start a capture from one terminal in `eye-of-sauron/lab/`:

```bash
vagrant ssh ids -c 'sudo capture-lab /workspace/lab/captures/test-traffic.pcap'
```

Generate a controlled scan from another:

```bash
vagrant ssh attacker -c 'nmap -sT -Pn 192.168.57.20'
```

Press `Ctrl-C` in the first terminal. The capture will be available at
`lab/captures/test-traffic.pcap` on the host.

### Common Vagrant commands

Run these commands from `eye-of-sauron/lab/`:

| Task | Command |
|---|---|
| Show status | `vagrant status` |
| Start the lab | `vagrant up --provider=vmware_desktop` |
| Stop the lab | `vagrant halt` |
| Connect to a VM | `vagrant ssh attacker`, `ids`, or `target` |
| Re-run setup | `vagrant provision` |
| Delete the lab | `vagrant destroy` |

Use `vagrant destroy`, rather than manually deleting `lab/.vagrant/`, when the
lab needs to be recreated. Files saved only inside a VM are deleted, while the
repository and `/workspace` files remain.
