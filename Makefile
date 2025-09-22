SHELL := bash
DEBUG ?= false
DRY_RUN ?= true
SKIP_TESTS ?= false
GITHUB_STEP_SUMMARY ?=

#ifeq ($(shell if [[ -n "$${GITHUB_STEP_SUMMARY}" ]]; then echo "running-in-workflow"; else echo "running-in-shell"; fi), running-in-workflow)
#	DEBUG = true
#endif

ifneq (${GITHUB_STEP_SUMMARY},)
	DEBUG = true
endif

_RELEASE_PUBLISH ?=
ifneq (${DRY_RUN},true)
	_RELEASE_PUBLISH= -Drelease.autopublish=true
endif

_RELEASE_SKIP_TESTS ?=
ifneq (${SKIP_TESTS},false)
	_RELEASE_SKIP_TESTS= -DskipTests=true -DskipITs=true
endif

ifeq (${DEBUG},false)
	MVNCMD ?= mvn
else
	MVNCMD ?= mvn -B -X -ntp
endif

fmt:
	$(MVNCMD) fmt:format

compile:
	$(MVNCMD) compile test-compile -Dfmt.skip=true -Dclirr.skip=true -Danimal.sniffer.skip=true

verify:
	$(MVNCMD) verify -DskipTests

test-unit:
	$(MVNCMD) test -Dfmt.skip=true -Dclirr.skip=true -Danimal.sniffer.skip=true

test: fmt compile verify test-unit

release-prepare:
ifeq ($(shell if [[ -n "$${GPG_PASSPHRASE}" ]]; then echo "present"; else echo "absent"; fi), absent)
	@echo "environment variable GPG_PASSPHRASE has to be set"
	@exit 1
endif
	MAVEN_OPTS="$${MAVEN_OPTS}$(_RELEASE_SKIP_TESTS)" $(MVNCMD) release:prepare -Drelease.push.changes=false -Dgpg.passphrase=$${GPG_PASSPHRASE}

.release:
ifeq ($(shell if [[ -n "$${GPG_PASSPHRASE}" ]]; then echo "present"; else echo "absent"; fi), absent)
	@echo "environment variable GPG_PASSPHRASE has to be set"
	@exit 1
endif
ifeq ($(shell if [[ -n "$${SONATYPE_TOKEN_USERNAME}" ]]; then echo "present"; else echo "absent"; fi), absent)
	@echo "environment variable SONATYPE_TOKEN_USERNAME has to be set"
	@exit 1
endif
ifeq ($(shell if [[ -n "$${SONATYPE_TOKEN_PASSWORD}" ]]; then echo "present"; else echo "absent"; fi), absent)
	@echo "environment variable SONATYPE_TOKEN_PASSWORD has to be set"
	@exit 1
endif
	MAVEN_OPTS="$${MAVEN_OPTS}$(_RELEASE_SKIP_TESTS)" $(MVNCMD) release:perform -Dgpg.passphrase=$${GPG_PASSPHRASE} $(_RELEASE_PUBLISH)

release:
	$(MAKE) .release DRY_RUN=false

release-dry-run:
	$(MAKE) .release DRY_RUN=true


