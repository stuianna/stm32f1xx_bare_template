# Project name
PROJECT=project

# User defined global definitions
DEFS = 

# Directory Structure
BINDIR=bin
INCDIR=inc
SRCDIR=src
LIBDIR=lib
OBJDIR=obj

# Startup File
# Choose the correct one from lib/CMSIS/startup
STARTUP = startup_stm32f10x_md.s

# Linker Script, choose one from util/linker or modify one to suit
# The files are fundamentally the same, just the memory mapping differs.
LDSCRIPT=stm32f103vb_flash.ld

OPENOCD_INTERFACE=stlink-v2
OPENOCD_TARGET=stm32f1x

# Define the processor family
DEFS+= -DSTM32F10X_MD

# C compilation flags
CFLAGS= -Wall -Wextra -Os -fno-common -ffunction-sections -fdata-sections -std=c99

# C++ compilation flags
CXXFLAGS= -Wall -Wextra -Os -fno-common -ffunction-sections -fdata-sections -std=c++11

# Linker flags
LDFLAGS= -Wl,--gc-sections --static -nostartfiles -Wl,-Map=obj/$(PROJECT).map,--cref

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
.PHONY: all release release-memopt debug clean flash erase

all: release

release-memopt-blame: CFLAGS+=-g
release-memopt-blame: CXXFLAGS+=-g
release-memopt-blame: LDFLAGS+=-g -Wl,-Map=$(BINDIR)/output.map
release-memopt-blame: release-memopt
release-memopt-blame:
	@echo "Top 10 space consuming symbols from the object code ...\n"
	$(NM) -A -l -C -td --reverse-sort --size-sort $(BINDIR)/$(BINELF) | head -n10 | cat -n # Output legend: man nm
	@echo "\n... and corresponging source files to blame.\n"
	$(NM) --reverse-sort --size-sort -S -tx $(BINDIR)/$(BINELF) | head -10 | cut -d':' -f2 | cut -d' ' -f1 | $(A2L) -e $(BINDIR)/$(BINELF) | cat -n # Output legend: man addr2line

release-memopt: DEFS+=-DCUSTOM_NEW -DNO_EXCEPTIONS
release-memopt: CFLAGS+=-Os -ffunction-sections -fdata-sections -fno-builtin # -flto
release-memopt: CXXFLAGS+=-Os -fno-exceptions -ffunction-sections -fdata-sections -fno-builtin -fno-rtti # -flto
release-memopt: LDFLAGS+=-Os -Wl,-gc-sections --specs=nano.specs # -flto
$(patsubst %.c,%.o,$(wildcard *.c))release-memopt: release

debug: CFLAGS+=-g
debug: CXXFLAGS+=-g
debug: LDFLAGS+=-g
debug: release

release: $(BINDIR)/$(BINHEX)

$(BINDIR)/$(BINHEX): $(BINDIR)/$(BINELF)
	$(CP) -O ihex $< $@
	@echo "Objcopy from ELF to IHEX complete!\n"

$(BINDIR)/$(BINELF): $(OBJECTS)
	mkdir -p $(BINDIR)
	$(CXX) $(OBJECTS) $(LDFLAGS) -o $@
	@echo "Linking complete!\n"
	$(SIZE) $(BINDIR)/$(BINELF)

$(OBJDIR)/%.o: %.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $< -o $@
	@echo "Compiled "$<"!\n"

$(OBJDIR)/%.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $< -o $@
	@echo "Compiled "$<"!\n"

$(OBJDIR)/%.o: %.s
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $< -o $@
	@echo "Assambled "$<"!\n"

flash: release
	@openocd -f interface/$(OPENOCD_INTERFACE).cfg \
		-f target/$(OPENOCD_TARGET).cfg \
        -c "program $(BINDIR)/$(PROJECT).elf verify" \
		-c "reset" \
        -c "exit"
erase:
	@openocd -f interface/$(OPENOCD_INTERFACE).cfg \
		-f target/$(OPENOCD_TARGET).cfg \
		-c "init" \
		-c "halt" \
		-c "$(OPENOCD_TARGET) mass_erase 0" \
        -c "exit"
clean:
	rm -rf obj bin

print-%  : ; @echo $* = $($*)

