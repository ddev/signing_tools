
test:
	bats --verbose-run tests

.PHONY: signing-integration-test
signing-integration-test:
	./test_signing_integration.sh
