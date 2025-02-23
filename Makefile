# See LICENSE for licensing information.

PROJECT = ranch
PROJECT_DESCRIPTION = Socket acceptor pool for TCP protocols.
PROJECT_VERSION = 2.0.0-rc.1
PROJECT_REGISTERED = ranch_server

# Options.

CT_OPTS += -pa test -ct_hooks ranch_ct_hook [] # -boot start_sasl
PLT_APPS = crypto public_key tools

# Dependencies.

LOCAL_DEPS = ssl

DOC_DEPS = asciideck

TEST_DEPS = $(if $(CI_ERLANG_MK),ci.erlang.mk) ct_helper havoc
dep_ct_helper = git https://github.com/ninenines/ct_helper master
dep_havoc = git https://github.com/ankhers/havoc master

# CI configuration.

dep_ci.erlang.mk = git https://github.com/ninenines/ci.erlang.mk master
DEP_EARLY_PLUGINS = ci.erlang.mk

AUTO_CI_OTP ?= OTP-21+
AUTO_CI_HIPE ?= OTP-LATEST
# AUTO_CI_ERLLVM ?= OTP-LATEST
AUTO_CI_WINDOWS ?= OTP-21+

# Standard targets.

include erlang.mk

# Don't run the havoc test suite by default.

ifndef FULL
CT_SUITES := $(filter-out havoc,$(CT_SUITES))
endif

# Compile options.

ERLC_OPTS += +warn_missing_spec +warn_untyped_record
TEST_ERLC_OPTS += +'{parse_transform, eunit_autoexport}'

# Dialyze the tests.

DIALYZER_OPTS += --src -r test

# Use erl_make_certs from the tested release during CI
# and ensure that ct_helper is always recompiled.
#
# Note that erl_make_certs was removed from OTP-20.1. For now
# we are fine using the most recent version from OTP-20.

ci-setup:: $(DEPS_DIR)/ct_helper
	$(gen_verbose) cp ~/.kerl/builds/$(CI_OTP_RELEASE)/otp_src_git/lib/ssl/test/erl_make_certs.erl deps/ct_helper/src/ || true
	$(gen_verbose) $(MAKE) -C $(DEPS_DIR)/ct_helper clean app

# Prepare for the release.

prepare_tag:
	$(verbose) echo -n "Most recent tag:            "
	$(verbose) git tag | tail -n1
	$(verbose) git verify-tag `git tag | tail -n1`
	$(verbose) echo -n "MAKEFILE: "
	$(verbose) grep -m1 PROJECT_VERSION Makefile
	$(verbose) echo -n "APP:                 "
	$(verbose) grep -m1 vsn ebin/$(PROJECT).app | sed 's/	//g'
	$(verbose) echo
	$(verbose) echo "Links in the README:"
	$(verbose) grep http.*:// README.asciidoc
	$(verbose) echo
	$(verbose) echo "Titles in most recent CHANGELOG:"
	$(verbose) for f in `ls -rv doc/src/guide/migrating_from_*.asciidoc | head -n1`; do \
		echo $$f:; \
		grep == $$f; \
	done
