#
# %CopyrightBegin%
#
# SPDX-License-Identifier: Apache-2.0
#
# Copyright Ericsson AB 1998-2025. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# %CopyrightEnd%
#
include $(ERL_TOP)/make/target.mk

include $(ERL_TOP)/make/$(TARGET)/otp.mk

include ../epmd.mk

EBIN = .

# ----------------------------------------------------
# Target Specs
# ----------------------------------------------------

MODULES= epmd_SUITE

ERL_FILES= $(MODULES:%=%.erl)

TARGET_FILES = $(MODULES:%=$(EBIN)/%.$(EMULATOR))

EMAKEFILE=Emakefile

# ----------------------------------------------------
# Release directory specification
# ----------------------------------------------------
RELEPMDDIR   = $(RELEASE_PATH)/epmd_test

# ----------------------------------------------------
# FLAGS
# ----------------------------------------------------

ERL_COMPILE_FLAGS += $(EPMD_FLAGS) +nowarn_missing_spec_documented

# ----------------------------------------------------
# Targets
# ----------------------------------------------------

tests debug opt: $(EMAKEFILE)

$(EMAKEFILE): Makefile $(ERL_FILES)
	$(ERL_TOP)/make/make_emakefile $(ERL_COMPILE_FLAGS) \
	-o$(EBIN) $(MODULES) > $(EMAKEFILE)

clean:
	rm -f $(TARGET_FILES)
	rm -f core *~

docs:

# ----------------------------------------------------
# Release Target
# ---------------------------------------------------- 
include $(ERL_TOP)/make/otp_release_targets.mk

release_spec:

release_tests_spec: opt
	$(INSTALL_DIR) "$(RELEPMDDIR)"
	$(INSTALL_DATA) epmd.spec $(ERL_FILES) \
		$(EMAKEFILE) "$(RELEPMDDIR)"
	chmod -R u+w "$(RELEPMDDIR)"

release_docs_spec:





