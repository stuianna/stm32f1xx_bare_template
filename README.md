# STM32F1XX Bare Metal Template

A makefile style template for STM32f1xx microcontrollers. Uses CMSIS header (inc/CMSIS/) file for microcontroller register definitions. Doesn't include STM32 Hal or standard peripheral library, designed for direct register "bare metal" access. The makefile is configured for the STM32f103xB microcontroller, but can be adapted for other STM32f1xx devices, see below.

## Requirements

The [GNU arm embedded toolchain](https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads) is used to build the target. Get it with:
```
# Debian based
sudo apt-get install gcc-arm-none-eabi

# Arch based
pacman -S arm-none-eabi-gcc
```

[Openocd](openocd.org) is used to deploy to the target microcontroller. Get it with:

```
# Debian based
sudo apt-get install openocd

# Arch based
pacman -S openocd

```

StlinkV2 USB probe is used to interface with the microcontroller using SWD. It can be found for around 10 USD on ebay. Other programmers can be used by modifying the flash recipe in the Makefile.

### Configuration

StlinkV2 needs to have a udev rule added to function correctly. This can be done by running the following:

```
echo 'ATTRS{idVendor}=="0483",ATTRS{idProduct}=="3748",MODE="0666"' | sudo tee -a /etc/udev/rules.d/99-stlink.rules
sudo udevadm control --reload-rules
```

## Usage

Clone the repository, change into the directory and compile.

```
git clone https://github.com/stuianna/stm32f1xx_bare_template.git
cd stm32f1xx_bare_template
make
```
All source code should be placed in directory `src`.

### Makefile Recipies

```
make            # Calls make release
make release    # Compile all source files and link.
make clean      # Remove all object and binary files.
make flash      # Deploy the binary to the microcontroller using openocd.
make erase      # Erase all memory on the target microcontroller using openocd.
make memory     # Prints the top 10 functions which occupy the most memory.
make debug      # Compile all source with addition debug flags (-g3)
make print-VAR  # Prints the makefile variable 'VAR', for debugging makefile.
```

### Arm Math

The arm-math library is included, but not enabled. To use it include `<arm_math.h>` in a source file and uncomment `#USE_ARM_MATH=1` in the Makefile. Note that the arm math uses a fair chunk of space.

## Adapting for Other STM32f1xx Devices

The template should (but not tested) work for all other STM32f1xx devices. To change device, three parts in the Makefile need to be changed.

```
STARTUP = startup_stm32f103xb.s         # Choose the correct one for the device (lib/CMSIS/startup).
LDSCRIPT=STM32F103XB_FLASH.ld           # Choose the correct one for the device (util/linker).
DEFS+= -DSTM32F103xB                    # Change the include for the device (inc/CMSIS/stm32f1xx.h).
```

