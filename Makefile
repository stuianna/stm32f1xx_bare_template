# Project name
PROJECT=project

# User defined global definitions
DEFS =

# Directory Structure
BINDIR=bin
INCDIR=inc
INCDIR+=lib
SRCDIR=src
LIBDIR=lib
OBJDIR=obj

# Uncomment to use the arm-math library (DSP, PID, MATH functions)
# This is pretty space hungy
#USE_ARM_MATH=1

# Startup File
# Choose the correct one from lib/CMSIS/startup
STARTUP = startup_stm32f103xb.s

# Linker Script, choose one from util/linker or modify one to suit
# The files are fundamentally the same, just the memory mapping differs.
LDSCRIPT=STM32F103XB_FLASH.ld

OPENOCD_INTERFACE=stlink-v2
OPENOCD_TARGET=stm32f1x


# Define the processor family
DEFS+= -DSTM32F103xB

# C compilation flags
CFLAGS= -Wall -Wextra -Os -fno-common -ffunction-sections -fdata-sections -std=c99 -g

# C++ compilation flags
CXXFLAGS= -Wall -Wextra -Os -fno-common -ffunction-sections -fdata-sections -std=c++11 -g

# Linker flags
LDFLAGS= -Wl,--gc-sections --static -Wl,-Map=bin/$(PROJECT).map,--cref

ifdef USE_ARM_MATH
ARM_LIB_DIR=$(LIBDIR)/ARM
ARM_STATIC_LIB=arm_cortexM3l_math
DEFS += -DARM_MATH_CM3
LDFLAGS+= --specs=nosys.specs -L$(ARM_LIB_DIR) -l$(ARM_STATIC_LIB)
else
LDFLAGS+= --specs=nosys.specs				# This was non.specs, but didn't work for a more complex project 
endif

# MCU FLAGS -> These can be found by sifting through openocd makefiles
# Shouldn't need to be changed over the stm32f1xx family
MCFLAGS=-mcpu=cortex-m3 -mthumb -mlittle-endian -msoft-float -mfix-cortex-m3-ldrd

# GNU ARM Embedded Toolchain
CC=arm-none-eabi-gcc
CXX=arm-none-eabi-g++
LD=arm-none-eabi-ld
AR=arm-none-eabi-ar
AS=arm-none-eabi-as
CP=arm-none-eabi-objcopy
OD=arm-none-eabi-objdump
NM=arm-none-eabi-nm
SIZE=arm-none-eabi-size
A2L=arm-none-eabi-addr2line

# Find source files
ASOURCES=$(LIBDIR)/CMSIS/startup/$(STARTUP)
CSOURCES=$(shell find -L $(SRCDIR) $(LIBDIR) -name '*.c')
CPPSOURCES=$(shell find -L $(SRCDIR) $(LIBDIR) -name '*.cpp')

# Find header directories
INC=$(shell find -L $(INCDIR) -name '*.h' -exec dirname {} \; | uniq)
INC+=$(shell find -L $(INCDIR) -name '*.hpp' -exec dirname {} \; | uniq)
INCLUDES=$(INC:%=-I%)

CFLAGS += -c $(MCFLAGS) $(DEFS) $(INCLUDES)
CXXFLAGS += -c $(MCFLAGS) $(DEFS) $(INCLUDES)

AOBJECTS = $(patsubst %,obj/%,$(ASOURCES))
COBJECTS = $(patsubst %,obj/%,$(CSOURCES))
CPPOBJECTS = $(patsubst %,obj/%,$(CPPSOURCES))

OBJECTS=$(AOBJECTS:%.s=%.o) $(COBJECTS:%.c=%.o) $(CPPOBJECTS:%.cpp=%.o)

# Define output files ELF & IHEX
BINELF=$(PROJECT).elf
BINHEX=$(PROJECT).hex

# Additional linker flags
LDFLAGS += -T util/linker/$(LDSCRIPT) $(MCFLAGS) 

# Build Rules
.PHONY: all release debug clean flash erase

all: release

memory: CFLAGS+=-g
memory: CXXFLAGS+=-g
memory: LDFLAGS+=-g -Wl,-Map=$(BINDIR)/$(PROJECT).map
memory:
	@echo -e "\033[0;32m[Top Memory Use]\033[0m"
	@$(NM) -A -l -C -td --reverse-sort --size-sort $(BINDIR)/$(BINELF) | head -n10 | cat -n

debug: CFLAGS+=-g3
debug: CXXFLAGS+=-g3
debug: LDFLAGS+=-g3
debug: release

release: $(BINDIR)/$(BINHEX)

$(BINDIR)/$(BINHEX): $(BINDIR)/$(BINELF)
	@$(CP) -O ihex $< $@
	@echo -e "\033[0;32m [OK] \033[0m       \033[0;33m Converted:\033[0m" $<
	@echo -e "\n\033[0;32m[Binary Size]\033[0m"
	@$(SIZE) $(BINDIR)/$(BINELF)

$(BINDIR)/$(BINELF): $(OBJECTS)
	@mkdir -p $(BINDIR)
	@$(CXX) $(OBJECTS) $(LDFLAGS) -o $@
	@echo -e "\033[0;32m [OK] \033[0m       \033[0;33m Linked:\033[0m" $<

$(OBJDIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	@$(CXX) $(CXXFLAGS) $< -o $@
	@echo -e "\033[0;32m [OK] \033[0m       \033[0;33m Compiled:\033[0m" $<

$(OBJDIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) $< -o $@
	@echo -e "\033[0;32m [OK] \033[0m       \033[0;33m Compiled:\033[0m" $<

$(OBJDIR)/%.o: %.s
	@echo -e "\033[0;32m[Compiling]\033[0m"
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) $< -o $@
	@echo -e "\033[0;32m [OK] \033[0m       \033[0;33m Assembled:\033[0m" $<

flash: release
	@echo -e "\n\033[0;32m[Flashing]\033[0m"
	@openocd -f interface/$(OPENOCD_INTERFACE).cfg \
		-f target/$(OPENOCD_TARGET).cfg \
        -c "program $(BINDIR)/$(PROJECT).elf verify" \
		-c "reset" \
        -c "exit"
erase:
	@echo -e "\n\033[0;32m[Erasing]\033[0m"
	@openocd -f interface/$(OPENOCD_INTERFACE).cfg \
		-f target/$(OPENOCD_TARGET).cfg \
		-c "init" \
		-c "halt" \
		-c "$(OPENOCD_TARGET) mass_erase 0" \
        -c "exit"
clean:
	@rm -rf obj bin

print-%  : ; @echo $* = $($*)

