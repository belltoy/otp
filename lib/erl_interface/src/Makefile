# 
# %CopyrightBegin%
#
# SPDX-License-Identifier: Apache-2.0
#
# Copyright Ericsson AB 1996-2025. All Rights Reserved.
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

# Invoke with GNU make or clearmake -C gnu.
#

# FIXME let configure put in this last part TARGET

include $(ERL_TOP)/make/output.mk
include $(ERL_TOP)/make/target.mk

debug opt shared gcov lcnt valgrind asan:
ifndef TERTIARY_BOOTSTRAP
	$(make_verbose)$(MAKE) -f $(TARGET)/Makefile TYPE=$@
endif

clean depend docs release release_docs tests release_tests check:
	$(make_verbose)$(MAKE) -f $(TARGET)/Makefile $@
