################################################################################
## Copyright (c) 2023 Analog Devices, Inc.
## SPDX short identifier: BSD-1-Clause
################################################################################

HDL_PROJECT_PATH := $(subst scripts/project-lattice.mk,,$(lastword $(MAKEFILE_LIST)))

include $(HDL_PROJECT_PATH)../quiet.mk

PROPEL_BUILDER := propelbld

ifeq ($(OS), Windows_NT)
    RADIANT := pnmainc
else
    RADIANT := radiant
endif

# Common dependencies that all projects have
M_DEPS += system_project_bd.tcl
M_DEPS += system_bd.tcl
M_DEPS += system_project.tcl
M_DEPS += system_top.v
M_DEPS += $(wildcard *system_constr.pdc) # Not all projects have this file
M_DEPS += $(wildcard *system_constr.sdc) # Not all projects have this file
M_DEPS += $(wildcard *system_constr.tcl) # Not all projects have this file
M_DEPS += $(HDL_PROJECT_PATH)scripts/adi_project_lattice_bd.tcl
M_DEPS += $(HDL_PROJECT_PATH)scripts/adi_project_lattice.tcl
M_DEPS += $(HDL_PROJECT_PATH)../scripts/adi_env.tcl

.PHONY: all pb rd clean clean-pb clean-rd

all: $(PROJECT_NAME)/$(PROJECT_NAME)/$(PROJECT_NAME).sbx \
		$(PROJECT_NAME)/$(PROJECT_NAME).rdf

pb: $(PROJECT_NAME)/$(PROJECT_NAME)/$(PROJECT_NAME).sbx

rd: $(PROJECT_NAME)/$(PROJECT_NAME).rdf

clean:
	-rm -Rf ${PROJECT_NAME}
	-rm -f $(wildcard *.log)
	-rm -Rf ./ipcfg
	-rm -Rf $(filter-out . .. ./. ./.., $(wildcard .*))

clean-pb:
	-rm -Rf $(filter-out $(PROJECT_NAME)/$(PROJECT_NAME)/$(PROJECT_NAME).v, \
		$(wildcard $(PROJECT_NAME)/$(PROJECT_NAME)/*))
	-rm -f $(PROJECT_NAME)/.socproject
	-rm -Rf ./ipcfg
	-rm -Rf $(filter-out . .. ./. ./.., $(wildcard .*))

clean-rd:
	-rm -Rf $(filter-out $(PROJECT_NAME)/$(PROJECT_NAME) \
		$(PROJECT_NAME)/.socproject, \
		$(wildcard $(PROJECT_NAME)/*))
	-rm -Rf $(filter-out $(PROJECT_NAME)/$(PROJECT_NAME) \
		$(PROJECT_NAME)/.socproject \
		$(PROJECT_NAME)/. \
		$(PROJECT_NAME)/.., $(wildcard $(PROJECT_NAME)/.*))

$(PROJECT_NAME)/$(PROJECT_NAME)/$(PROJECT_NAME).sbx: $(M_DEPS)
	$(call build, \
		$(PROPEL_BUILDER) system_project_bd.tcl ${PROJECT_NAME}, \
		$(PROJECT_NAME)_propel_builder.log, \
		$(HL)$(PROJECT_NAME)$(NC) project)

$(PROJECT_NAME)/$(PROJECT_NAME).rdf: $(M_DEPS)
	$(call build, \
		$(RADIANT) system_project.tcl ${PROJECT_NAME}, \
		$(PROJECT_NAME)_radiant.log, \
		$(HL)$(PROJECT_NAME)$(NC) project)
