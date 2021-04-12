# Amazon FPGA Hardware Development Kit
#
# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions and
# limitations under the License.

ifndef VIVADO_TOOL_VERSION
$(error Environment variable VIVADO_TOOL_VERSION not set. please source hdk_setup.sh)
else
$(info VIVADO_TOOL_VERSION = $(VIVADO_TOOL_VERSION))
endif

ifndef FLETCHER_AWS_DIR
$(error Environment variable FLETCHER_AWS_DIR not set. please source fletcher-aws sourceme.sh)
endif
ifndef FLETCHER_AWS_SIM_BUILD_DIR
$(error Environment variable FLETCHER_AWS_SIM_BUILD_DIR not set. Set this to where you built the simulation runtime.)
endif

export TEST ?= test_null
export C_TEST ?= test_null

export SCRIPTS_DIR = $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
export CL_ROOT = $(realpath $(SCRIPTS_DIR)/../..)
export SDK_DIR = $(AWS_FPGA_REPO_DIR)/sdk

export C_COMMON_DIR        = $(HDK_COMMON_DIR)/software
export C_SDK_USR_INC_DIR   = $(SDK_DIR)/userspace/include
export C_SDK_USR_UTILS_DIR = $(SDK_DIR)/userspace/utils
export C_INC_DIR  = $(CL_ROOT)/software/runtime
export C_SRC_DIR  = $(CL_ROOT)/software/runtime

#The common fletcher AWS platform code 
#This Makefile cannot use the library due to link order; 
#the fletcher_aws_sim lib needs functions from sh_dpi_tasks.c
export FLETCHER_AWS_SIM_SRC_DIR  = $(FLETCHER_AWS_DIR)/runtime/runtime_sim/src

export TEST_NAME =  $(CL_ROOT)/verif/tests/$(TEST).sv

ifeq ($(C_TEST),test_null)
  export C_TEST_NAME = $(HDK_COMMON_DIR)/software/src/$(C_TEST).c
else
  export C_TEST_NAME = $(C_SRC_DIR)/$(C_TEST).cpp
endif

export SIM_ROOT = $(CL_ROOT)/verif/sim/$(SIMULATOR)

ifeq ($(C_TEST),test_null)
  ifeq ($(AXI_MEMORY_MODEL), 1)
    ifeq ($(ECC_DIRECT), 1)
        export SIM_DIR = $(SIM_ROOT)/$(TEST)_sv_fast_ecc_direct
    else
      ifeq ($(ECC_RAND), 1)
        export SIM_DIR = $(SIM_ROOT)/$(TEST)_sv_fast_ecc_rnd
      else
        ifeq ($(DDR_BKDR), 1)
         export SIM_DIR = $(SIM_ROOT)/$(TEST)_sv_fast_bkdr
	else
         export SIM_DIR = $(SIM_ROOT)/$(TEST)_sv_fast
	endif
      endif
    endif
  else
   ifeq ($(ECC_DIRECT), 1)
        export SIM_DIR = $(SIM_ROOT)/$(TEST)_sv_ecc_direct
    else
      ifeq ($(ECC_RAND), 1)
        export SIM_DIR = $(SIM_ROOT)/$(TEST)_sv_ecc_rnd
      else
        ifeq ($(DDR_BKDR), 1)
         export SIM_DIR = $(SIM_ROOT)/$(TEST)_sv_bkdr
	else
         export SIM_DIR = $(SIM_ROOT)/$(TEST)_sv
	endif
      endif
    endif
  endif
else
  export SIM_DIR = $(SIM_ROOT)/$(C_TEST)_c
  ifndef TEST_RECORDBATCH_BASE
    $(error Environment variable TEST_RECORDBATCH_BASE not set. Please set this environment variable to the location (including the path) of the test recordbatches (with the same schema that was passed to fletchgen to generate the base vhdl design), excluding the number+extension suffix (000.rb). For example: `export TEST_RECORDBATCH_BASE=~/workspaces/example/gen/rematch`.)
  endif
endif

export XILINX_IP   = $(HDK_SHELL_DESIGN_DIR)/ip
export SH_LIB_DIR  = $(HDK_SHELL_DESIGN_DIR)/lib
export SH_INF_DIR  = $(HDK_SHELL_DESIGN_DIR)/interfaces
export SH_SH_DIR   = $(HDK_SHELL_DESIGN_DIR)/sh_ddr/sim

SV_TEST_LIST = test_hello_world

#This next line has multiple layers of ugliness; 
# 1) There is no clean way to pass arguments to the build process, we're misusing --gcc_link_options to do that here
# 2) fletcher_aws_sim is a library, that is loaded dynamically during runtime. 
#    However, the library needs functions from sh_dpi_tasks.c. So we're adding it as a source file as well, so the linker
#    can find everything and we don't get any undefined symbol errors.
C_FILES      = $(C_TEST_NAME) $(FLETCHER_AWS_SIM_SRC_DIR)/fletcher_aws_sim.c $(C_SDK_USR_UTILS_DIR)/sh_dpi_tasks.c \
$(C_COMMON_DIR)/src/fpga_pci_sv.c --gcc_compile_options I$(FLETCHER_AWS_SIM_SRC_DIR) --gcc_link_options \
L$(FLETCHER_AWS_SIM_BUILD_DIR) --gcc_link_options lfletcher_aws_sim --gcc_link_options lfletcher

ifeq ($(XCHK), 1)
  all:	make_sim_dir compile_chk run
else
  all:	make_sim_dir compile run
endif

include $(HDK_COMMON_DIR)/verif/tb/scripts/Makefile.common.inc
