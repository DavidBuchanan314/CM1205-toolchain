# CM1205-toolchain
Instructions for assembling, running, and debugging the MASM syntax assembly featured in the CM1205 module at Cardiff University

## Requirements:
 - JWasm (assembler)
 - MinGW binutils (specifically, `ld` for linking with the Windows libraries)
 - wine (for execution)
 - gdb.exe (for debugging)
 - MASM32 SDK

These tools can likely all be installed via your system's Package Manager.
However, I found the version of gdb.exe that shipped with MinGW to be very unstable, and eventually I found an older version that worked:

ftp://ftp.equation.com/gdb/snapshot/32/gdb.exe (Version 7.7.50-20140303)

The MASM32 SDK is needed in order to call Windows library functions from assembly. This must be installed via Wine.

## Usage:

See the `Makefile` in the `hello` directory for an example of how to use these tools together to compile a simple program that uses the Windows API.

## Issues:

 - I've been unable to get JWasm to output line number debugging information in a way which is compatible with the rest of the toolchain.
