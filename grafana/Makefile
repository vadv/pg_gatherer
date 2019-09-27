dashboard: submodule_check
	jsonnet -J jsonnet jsonnet/dashboard.jsonnet -o dashboard.json

submodules:
	git submodule init
	git submodule update

submodule_update:
	git submodule update

submodule_pull:
	git submodule foreach "git pull"

submodule_check:
	@-test -d .git -a .gitmodules && \
		git submodule status \
		| grep -q "^-" \
		&& $(MAKE) submodules || true
	@-test -d .git -a .gitmodules && \
		git submodule status \
		| grep -q "^+" \
		&& $(MAKE) submodule_update || true