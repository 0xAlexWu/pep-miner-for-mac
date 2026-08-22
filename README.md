# PEP MINER 

**Native Scrypt Mining on Apple Silicon**

**by X [@0xAlexWu](https://x.com/0xAlexWu)**

> Tested on Apple M2

---

## Overview

**PEP Miner** is a lightweight macOS script for exploring native Scrypt mining on Apple Silicon.

The project started from a simple question:

> **Can an Apple Silicon Mac perform real Scrypt proof-of-work and connect to a live Pepecoin mining workflow?**

The answer is yes.

PEP Miner automates the process of preparing the macOS environment, compiling an ARM64-native version of `cpuminer-opt`, benchmarking Scrypt performance, and connecting to a real Stratum mining endpoint.

It is built for developers, researchers, hobbyists, and anyone curious about:

* Scrypt
* Proof-of-Work
* Apple Silicon
* ARM64 optimization
* CPU mining
* Stratum
* Mining difficulty
* Share difficulty
* Mining pools
* Hardware benchmarking

This project is primarily a technical experiment and learning tool.

---

## Features

PEP Miner can automatically:

* Detect Apple Silicon hardware
* Detect macOS version
* Detect available CPU threads
* Check Xcode Command Line Tools
* Check Homebrew
* Install required build dependencies
* Download `cpuminer-opt`
* Compile a native ARM64 binary
* Apply Apple Silicon-specific compiler flags
* Run a 60-second Scrypt benchmark
* Connect to a live PEP-compatible Stratum endpoint
* Start multi-threaded Scrypt mining
* Display live hashrate
* Display incoming mining jobs
* Display network difficulty
* Display Stratum share difficulty
* Log build and mining activity
* Recover from temporary Stratum disconnections
* Reset local build files for clean testing

---

## Tested Environment

The original development environment:

```text
Apple M2
Architecture: arm64
CPU Threads: 8
macOS: Ventura
Compiler: Apple Clang
Algorithm: Scrypt
Parameters: N=1024, r=1
```

Measured benchmark:

```text
Benchmark: 49.07 kH/s
```

Typical sustained hashrate:

```text
45–55 kH/s
```

Example:

```text
8 of 8 miner threads started using 'scrypt' algorithm

Total: 45.63 kH/s
Total: 49.30 kH/s
Total: 46.57 kH/s

Benchmark: 49.07 kH/s
```

Performance will vary depending on:

* Apple Silicon generation
* macOS version
* Thermal conditions
* Background processes
* Compiler version
* CPU thread count
* Power conditions

---

## Apple Silicon

PEP Miner is designed for ARM64 Macs.

The script includes compiler profiles for Apple Silicon generations including:

```text
M1
M2
M3
M4
M5
```

For Apple M2 and M3, the build currently uses:

```bash
-O3 -march=armv8.6-a+crypto+sha3
```

The script automatically selects an appropriate compiler configuration based on the detected chip.

---

## Scrypt

PEP Miner uses the Scrypt Proof-of-Work algorithm.

Current parameters:

```text
N = 1024
r = 1
```

During startup, `cpuminer-opt` should report something similar to:

```text
Scrypt parameters: N=1024, R=1
```

PEP Miner uses `cpuminer-opt` as its underlying CPU mining engine.

---

## How It Works

A simplified mining flow looks like this:

```text
Apple Silicon CPU
        │
        ▼
Scrypt N=1024 r=1
        │
        ▼
Candidate Hash
        │
        ▼
Compare Against Target
        │
        ├── Valid Pool Share
        │
        └── Valid Network Block
```

The CPU continuously calculates candidate Scrypt hashes.

Each hash is compared against one or more difficulty targets.

A hash meeting the pool share target may be submitted as a valid share.

A much rarer hash meeting the full network target may represent a valid blockchain block.

---

## Shares vs Blocks

A pool share and a blockchain block are not the same thing.

For example:

```text
Network Difficulty: 42,625,000
Stratum Difficulty:     16,384
```

The pool's share target is easier than the full network target.

This allows miners to continuously prove that they are performing real computational work even when they are extremely unlikely to independently discover a full block.

A mining session may display:

```text
TTF @ 50.67 kH/s:

Block: 114580 years
Share: 5h53m
```

TTF means estimated **Time To Find**.

Mining is probabilistic.

A share may appear much earlier or much later than the displayed estimate.

---

## Installation

Download the script:

```bash
pep-miner-v0.2.4.sh
```

Make it executable:

```bash
chmod +x pep-miner-v0.2.4.sh
```

Start PEP Miner:

```bash
./pep-miner-v0.2.4.sh
```

---

## Running from Downloads on macOS

If the script is in your Downloads directory:

```bash
chmod +x ~/Downloads/pep-miner-v0.2.4.sh
~/Downloads/pep-miner-v0.2.4.sh
```

---

## Menu

PEP Miner provides an interactive menu:

```text
1) Full setup -> build -> benchmark -> start PEP mining
2) Install/build only
3) Benchmark only
4) Start PEP mining only
5) Safe Reset
6) Exit
```

---

## Full Setup

To run the complete workflow:

```bash
./pep-miner-v0.2.4.sh all
```

The script will perform:

```text
System Check
     │
     ▼
Xcode Command Line Tools
     │
     ▼
Homebrew
     │
     ▼
Dependencies
     │
     ▼
Download cpuminer-opt
     │
     ▼
Compile ARM64 Binary
     │
     ▼
Scrypt Benchmark
     │
     ▼
PEP Stratum Mining
```

---

## Install / Build Only

To install dependencies and build the miner:

```bash
./pep-miner-v0.2.4.sh install
```

---

## Benchmark Only

After the miner has been compiled:

```bash
./pep-miner-v0.2.4.sh benchmark
```

The benchmark runs Scrypt for approximately 60 seconds.

Example:

```text
* MODE       benchmark
* ALGO       scrypt
* PARAMS     N=1024 r=1
* THREADS    8
* DURATION   60 seconds
```

Example result:

```text
Benchmark: 49.07 kH/s
```

---

## Start Mining

If the miner is already installed:

```bash
./pep-miner-v0.2.4.sh mine
```

PEP Miner will ask for:

```text
AikaPool username:
Worker name:
Worker password:
```

The resulting worker identity follows the format:

```text
Username.WorkerName
```

Example:

```text
alex.m2
```

The worker password is the password configured for that worker on the pool.

Do not use your wallet seed phrase, private key, exchange password, or any important account password as a worker password.

---

## Default Stratum Endpoint

The current default endpoint is:

```text
stratum.aikapool.com:7941
```

The script connects using:

```text
stratum+tcp
```

The pool host and port can also be overridden through environment variables:

```bash
PEP_POOL_HOST=example.com \
PEP_POOL_PORT=1234 \
./pep-miner-v0.2.4.sh mine
```

---

## Successful Stratum Connection

A successful session may look like:

```text
Stratum connect stratum+tcp://stratum.aikapool.com:7941

8 of 8 miner threads started using 'scrypt' algorithm

Stratum extranonce1 0x48000029, extranonce2 size 4

Stratum connection established

New Stratum Diff 16384
Block 1176917
Job 5d40
```

This means the miner has:

1. Connected to the Stratum server
2. Received session parameters
3. Received a mining job
4. Started calculating real Scrypt hashes

---

## Accepted Shares

When the miner finds a hash satisfying the pool's assigned share difficulty, it may display:

```text
accepted
```

or:

```text
Submitted 1
Accepted 1
```

An accepted share proves that the miner successfully completed valid work at the pool difficulty.

It does **not** necessarily mean the miner discovered a full blockchain block.

Reward accounting depends on the payout system of the selected mining pool.

---

## New Blocks and New Work

During mining, you may see:

```text
New Block 1176918
New Work: Block 1176918
```

This does not mean your Mac discovered that block.

It means the network advanced and the pool sent a new mining job.

The miner automatically stops working on obsolete jobs and begins working on the latest block template.

---

## Automatic Reconnection

Temporary Stratum interruptions may occur:

```text
stratum_recv_line failed
Stratum connection reset
```

The underlying miner can reconnect automatically.

A successful reconnection may look like:

```text
Stratum connection established
New Block ...
New Work ...
```

---

## Safe Reset

PEP Miner includes a local reset command:

```bash
./pep-miner-v0.2.4.sh reset
```

Safe Reset removes the project's local build state and logs.

It does **not** remove:

```text
Homebrew
Xcode Command Line Tools
Shared Homebrew packages
Other development environments
```

This is useful when repeatedly testing the installation workflow.

After reset:

```bash
./pep-miner-v0.2.4.sh all
```

will rebuild the miner.

---

## Logs

PEP Miner stores diagnostic logs locally.

Build log:

```text
~/pep-miner/build.log
```

Mining log:

```text
~/pep-miner/mining.log
```

These logs are useful for debugging compilation or Stratum issues.

---

## Dependencies

PEP Miner may install packages including:

```text
autoconf
automake
ca-certificates
curl
gettext
gmp
jansson
libunistring
lz4
m4
mpfr
pcre2
pkgconf
zstd
```

Some macOS versions may compile certain dependencies from source.

This can take several minutes.

---

## Xcode Command Line Tools

Check whether Command Line Tools are installed:

```bash
xcode-select -p
```

If needed:

```bash
xcode-select --install
```

Older macOS versions may receive warnings about newer Command Line Tools.

---

## Homebrew

PEP Miner uses Homebrew for build dependencies.

Some network environments may have difficulty accessing Homebrew package infrastructure.

The script includes fallback logic for alternative Homebrew mirrors when appropriate.

---

## Terminal Colors

PEP Miner uses ANSI terminal colors.

Current status colors include:

```text
INFO      Cyan
OK        Green
WARN      Yellow
ERROR     Red
```

The ASCII banner uses:

```text
PEP       Green
MINER     Cyan
Author    Magenta
```

The underlying `cpuminer-opt` miner may also display colored status messages.

To disable PEP Miner colors:

```bash
NO_COLOR=1 ./pep-miner-v0.2.4.sh
```

---

## CPU Usage

Proof-of-Work is computationally intensive.

If all available CPU threads are enabled, CPU utilization may remain high for long periods.

Example:

```text
8 of 8 miner threads started using 'scrypt' algorithm
```

This is expected behavior.

---

## Thermal Considerations

Continuous Scrypt computation may keep the CPU under sustained load.

Users should monitor:

* Temperature
* Thermal throttling
* Fan behavior
* Battery temperature
* Power consumption
* Long-duration stability

Use adequate ventilation.

PEP Miner does not bypass macOS thermal protection.

---

## Mining Performance

An Apple M2 CPU producing approximately:

```text
50 kH/s
```

is extremely small compared with modern dedicated Scrypt mining hardware.

Modern Scrypt networks are dominated by ASIC miners.

This means the probability of independently discovering a full network block using a consumer CPU may be extraordinarily low.

That is expected.

PEP Miner is primarily interesting as a technical and computational experiment.

---

## Why Mine on a Mac?

Not because it is the most efficient mining hardware.

Because it is interesting.

Running real Scrypt Proof-of-Work on Apple Silicon provides a simple way to explore:

```text
Cryptographic hashing
Proof-of-Work
ARM64 optimization
Apple Silicon
CPU architecture
Mining difficulty
Stratum
Mining pools
Probability
Network hashrate
Compiler optimization
```

Sometimes the experiment itself is the point.

---

## Pool Mining vs Solo Mining

The current default configuration connects to a Stratum mining pool.

This means the default workflow is **pool mining**.

PEP Miner itself does not operate a pool.

True solo mining generally requires a different workflow where the miner attempts to discover a full network block for its own payout destination.

Future versions may explore additional pool, solo, AuxPoW, or local-node configurations.

---

## Security

Always inspect shell scripts before executing them.

For example:

```bash
cat pep-miner-v0.2.4.sh
```

or:

```bash
less pep-miner-v0.2.4.sh
```

PEP Miner does not require:

```text
Wallet private keys
Seed phrases
Exchange credentials
Apple ID passwords
Email passwords
```

Never enter a wallet seed phrase or private key into PEP Miner.

---

## What PEP Miner Does Not Do

PEP Miner does not operate:

* A mining pool
* A cryptocurrency exchange
* A brokerage service
* A custody service
* A wallet custody system
* A payment service
* A token sale
* A cloud mining platform
* A hashrate marketplace

PEP Miner does not custody user assets.

Mining pool accounts, workers, payout addresses, and rewards are handled directly between the user and the selected mining service.

---

## Research & Educational Purpose

PEP Miner began as a personal technical experiment.

Its primary areas of interest include:

```text
Scrypt
Apple Silicon
ARM64
CPU benchmarking
Stratum
Proof-of-Work
Mining protocols
Compiler optimization
Hardware performance
```

Potential future experiments include:

* M1 / M2 / M3 / M4 comparisons
* Performance cores vs efficiency cores
* Thread scaling
* Power efficiency
* NEON optimization
* Compiler flag comparisons
* Native Scrypt implementations
* Metal compute
* GPU Scrypt experiments
* Stratum instrumentation
* AuxPoW experiments
* Local-node mining
* Solo mining workflows

---

## Legal & Regulatory Notice

Cryptocurrency mining rules vary by jurisdiction.

Some jurisdictions restrict or prohibit cryptocurrency mining or related activities.

Users are responsible for understanding and complying with all applicable:

* Laws
* Regulations
* Electricity policies
* Network policies
* Tax requirements
* Contractual obligations

PEP Miner does not provide legal, financial, tax, or investment advice.

The availability of mining functionality in this open-source project should not be interpreted as a statement that cryptocurrency mining is permitted in every jurisdiction.

---

## No Warranty

PEP Miner is provided as-is for technical, research, and educational purposes.

Use it at your own risk.

The author is not responsible for:

* Hardware damage
* Thermal issues
* Excessive electricity usage
* Lost mining rewards
* Pool account problems
* Network interruptions
* Software incompatibility
* Financial losses
* Regulatory consequences

Always understand the software you run.

---

## Upstream Miner

PEP Miner uses:

**cpuminer-opt**

by **JayDDee**.

Repository:

```text
https://github.com/JayDDee/cpuminer-opt
```

PEP Miner is an automation and Apple Silicon environment wrapper around the upstream mining engine.

Credit for the underlying miner belongs to its respective developers and contributors.

---

## Author

**0xAlexWu**

X:

**[@0xAlexWu](https://x.com/0xAlexWu)**

---

## Version

Current script:

```text
pep-miner-v0.2.4.sh
```

Tested on:

```text
Apple M2
macOS Ventura
ARM64
Scrypt N=1024 r=1
```

---

## License

A permissive open-source license such as MIT is recommended for the PEP Miner wrapper script.

Third-party components remain subject to their respective licenses.

---

## PEP MINER

**Native Scrypt on Apple Silicon.**

**Tested on Apple M2.**

Built for curiosity.
