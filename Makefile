include Makefile.mk

help:
	$(call publish.help)
	$(call console.help)
	$(call dashboard.help)
	$(call ci.help)
	$(call github.help)

init:
	mix ecto.setup

dep:
	mix deps.get
	npm install # for commitizen

build:
	mix compile

commit.help:
	$(call commit.help)
	@echo "\n"
commit:
	@npx git-cz
release:
	npm run release

publish:
	$(call publish.help)
	@echo "\n"
publish.help:
	$(call publish.help)
	@echo "\n"
publish.dev:
	./publish/dev/packer.sh
publish.prod:
	./publish/production/packer.sh

# test
test:
	mix test
test.watch:
	mix test.watch
test.report:
	MIX_ENV=mix test.coverage
	$(call browse,"./cover/excoveralls.html")
test.report.text:
	MIX_ENV=mix test.coverage.short

# lint code
lint:
	mix lint # credo --strict
lint.static:
	mix lint.static # use dialyzer

# open iex with history support
console.help:
	$(call console.help)
	@echo "\n"
console:
	iex --erl "-kernel shell_history enabled" -S mix
console.dev:
	MIX_ENV=dev iex --erl "-kernel shell_history enabled" -S mix
console.mock:
	MIX_ENV=mock iex --erl "-kernel shell_history enabled" -S mix

# todo: monitor.apollo monitor.alicloud
dashboard:
	$(call dashboard.help)
	@echo "\n"
dashboard.help:
	$(call dashboard.help)
	@echo "\n"
dashboard.apollo:
	$(call browse,"$(DASHBOARD_APOLLO_LINK)")
dashboard.aliyun:
	$(call browse,"$(DASHBOARD_ALIYUN_LINK)")

# ci helpers
ci:
	$(call ci.help)
	@echo "\n"
ci.help:
	$(call ci.help)
	@echo "\n"
ci.build:
	$(call browse,"$(CI_BUILD_LINK)")
ci.coverage:
	$(call browse,"$(CI_COVERAGE_LINK)")
ci.codecov:
	$(call browse,"$(CI_CODECOV_LINK)")
ci.doc:
	$(call browse,"$(CI_DOC_LINK)")

# github helpers
github:
	$(call github.help)
	@echo "\n"
github.help:
	$(call github.help)
	@echo "\n"
github.code:
	$(call browse,"$(GITHUB_CODE_LINK)")
github.doc:
	$(call browse,"$(GITHUB_DOC_LINK)")
github.pr:
	$(call browse,"$(GITHUB_PR_LINK)")
github.issue:
	$(call browse,"$(GITHUB_ISSUE_LINK)")
github.issue.new:
	$(call browse,"$(GITHUB_ISSUE_LINK)/new")
github.app:
	$(call browse,"$(GITHUB_APP_LINK)")
