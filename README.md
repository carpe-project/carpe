Introduction
============

CARPE (Computer Architecture Research Platform for Exploration) is a
project that aims to provide configurable, synthesizable, and
interchangable RTL models of components suitable for computer
architecture research.

The set of tools available for academic computer architecture research
using open-source tools is currently quite limited.  Simulation is
often performed with high-level, event-counting simulators that are
highly configurable, but may provide imprecise results due to the
granularity of simulation.  The results of such simulators may be
incorrect due to behavior that cannot be characterized by the set of
available parameters.

More accurate simulation requires the use of RTL models, which can be
synthesized and simulated at nearly any level of precision desired.
This package provides RTL models for a simple, synthesizable VHDL
implementation of a 5-stage OpenRISC core, including instruction and
data caches, branch prediction, and (soon) memory management.
Floating-point is not supported.

The implementation is heavily componentized, and parts are designed to
be as independent as is practical from ISA-level details such as word
size and so on.  This has allowed, for example, the caches and branch
prediction structures to be reused without modification on cores
implementing different ISAs.  (Currently, the instruction cache
assumes fixed size, aligned instructions, and the data cache assumes
aligned accesses, however.)


Simulating the OR1KND core
==========================

Requirements:

* Linux: Windows/Mac OSX probably won't work.  Debian and Ubuntu are
  the primary development platforms.

* Git: required to download the source.

* a VHDL simulator: [GHDL](http://ghdl-updates.sourceforge.net/) and
  [Synopsys VCS](http://synopsys.com/) are currently supported.

* python 2.7, yacc/bison, lex/flex, gperf, ncurses: commonly available
  on Linux

* [SCons](http://www.scons.org/): a python-based build system.

* A recent native GCC and GNU binutils

* [The OpenRISC GCC toolchain](http://opencores.org/or1k/OpenRISC_GNU_tool_chain)
  will probably be useful

How to get started:

* Check out the source tree:

        ~ $ git clone https://github.com/carpe-project/carpe.git
        ~ $ cd carpe

* Configure your project.  A sample configuration for a 5-stage
  OpenRISC pipeline with associative caches, branch prediction, and
  MAC can be found at `proj/cpu_or1knd_i5_min_sim/config.sample-ghdl`:

        ~/carpe $ cp proj/cpu_or1knd_i5_min_sim/config.sample-ghdl .config

  If you want to modify the configuration, start the (kconfig-based)
  configuration front-end:
  
        ~/carpe $ scons config

  The path to the `.config` file can be changed with the `CONFIG`
  command line variable:

        ~/carpe $ scons CONFIG=foo.config config

* Once you're happy with your configuration, build it:

        ~/carpe $ scons

  Or if you want a custom `.config` file:
    
        ~/carpe $ scons CONFIG=foo.config

  Once the build completes, a simulator will be available as
  `build/cpu_or1knd_i5_min_sim/cpu_or1knd_i5_min_sim`.  This command
  is actually a wrapper script that provides options to the simulator
  and monitors its progress.  This script supports the following
  options:

  * `-v`: be verbose

  * `-c filename`: save a trace of committed instructions to the
    provided filename

  * `-z`: the commit trace will be compress with gzip prior to being
    written to disk

  * `-g` (currently VCS only): start a gui

  * `-f (elf|srec)`: the format of the argument executable file

  For example:

        ~/carpe $ or1knd-elf-gcc -o foo.exe foo.c
        ~/carpe $ ./build/cpu_sp_min_sim/cpu_sp_min_sim -v -f elf -z -c commit.log.gz foo.exe

  will compile the C program for bare-metal OpenRISC and execute it in
  the simulator.  Note that I/O is not yet supported (a UART is
  planned); however the simulator will return the exit code passed to
  the exit system call in the simulator to the host OS.
