# Installing PROS w/Atom for Development (on Windows)

These instructions are designed for Windows, but generally would be the same for most operating
systems barring their methods of installing programs.

These instructions also serve as a guide for installing a "release" version of PROS w/Atom except
developer options wouldn't be used.

## Prerequisites
 - Atom
 - clang
 - Python 3.5 (development only when frozen applications are available)
 - PROS Toolchain (arm-none-eabi GCC, automake)
 - Git (development only)

## Download repos
 - https://github.com/purduesigbots/pros-atom
 - https://github.com/purduesigbots/pros-cli

## Live Installing PROScli
With the CLI Repository cloned, open a console in that directory and run `pip3 install --editable .`
You should now be able to run `pros` from within the console.

## Link pros-atom to Atom
With the pros-atom repository cloned, open a console in that directory and run either:
 - `apm link -d .`
 - `apm link .`
The `-d` option installs the pros plugin in development mode, so that it can only be opened when explicitly loaded. See Atom documentation for more details.

## Running Atom for the first time with PROS
You will need to redownload the required node modules before the linked PROS plugin will work as intended. To do this, open the pros-atom directory in Atom and run the "Update Package Dependencies" command by pressing Ctrl+Shift+P and typing the command.
