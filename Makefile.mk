OS := ${shell uname}

.PHONY: test publish

BELONG = "coderplanets"
REPO = "coderplanets_server"

DASHBOARD_APOLLO_LINK = "https://engine.apollographql.com/account/gh.mydearxym/services"
DASHBOARD_ALIYUN_LINK = "https://home.console.aliyun.com/new"

CI_BUILD_LINK = "https://travis-ci.org/$(BELONG)/$(REPO)"
CI_COVER_LINK = "https://coveralls.io/github/$(BELONG)/$(REPO)"
CI_DOC_LINK = "https://inch-ci.org/github/$(BELONG)/$(REPO)"

GITHUB_CODE_LINK = "https://github.com/$(BELONG)/$(REPO)"
GITHUB_DOC_LINK = "https://github.com/$(BELONG)/$(REPO)/tree/dev/docs"
GITHUB_PR_LINK = "https://github.com/$(BELONG)/$(REPO)/pulls"
GITHUB_ISSUE_LINK = "https://github.com/$(BELONG)/$(REPO)/issues"

ifeq ($(OS),Darwin)  # Mac OS X
		BROWSER_TOOL = open
endif
ifeq ($(OS),Linux)
		BROWSER_TOOL = google-chrome
endif
ifeq ($(OS),Windows)
		BROWSER_TOOL = explorer
endif

define browse
	$(BROWSER_TOOL) "$(1)"
endef

define publish.help
	@echo "\n"
	@echo "  [valid publish commands]"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	@echo "  publish.dev  : pack & push code to aliyun for dev"
	@echo "               | need manually restart docker container on aliyun"
	@echo "  ..............................................................."
	@echo "  publish.prod : pack & push  code to for produnction"
	@echo "               | need manually restart docker container on aliyun"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
endef

define console.help
	@echo "\n"
	@echo "  [valid console commands]"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	@echo "  console      : run iex"
	@echo "  ..................................."
	@echo "  console.dev  : run iex in dev env"
	@echo "  ..................................."
	@echo "  console.mock : run iex in mock env"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
endef

define dashboard.help
	@echo "\n"
	@echo "  [valid dashboard commands]"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	@echo "  dashboard.apollo : graphql api status provide by apollo engine"
	@echo "                   | $(DASHBOARD_APOLLO_LINK)"
	@echo "  ................................................................................."
	@echo "  dashboard.aliyun : aliyun console"
	@echo "                   | $(DASHBOARD_ALIYUN_LINK)"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
endef

define ci.help
	@echo "\n"
	@echo "  [valid ci commands]"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	@echo "  ci.build : browse travis status"
	@echo "           | $(CI_BUILD_LINK)"
	@echo "  ......................................................................."
	@echo "  ci.cover : browse test coveralls status"
	@echo "           | $(CI_COVER_LINK)"
	@echo "  ......................................................................."
	@echo "  ci.doc   : browse doc coverage status"
	@echo "           | $(CI_DOC_LINK)"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
endef

define github.help
	@echo "\n"
	@echo "  [valid github commands]"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	@echo "  github.code      : browse source code in github"
	@echo "                   | $(GITHUB_CODE_LINK)"
	@echo "  ...................................................................................."
	@echo "  github.doc       : browse repo docs in github"
	@echo "                   | $(GITHUB_DOC_LINK)"
	@echo "  ...................................................................................."
	@echo "  github.pr        : browse PRs in github"
	@echo "                   | $(GITHUB_PR_LINK)"
	@echo "  ...................................................................................."
	@echo "  github.issue     : browse issues in github"
	@echo "                   | $(GITHUB_ISSUE_LINK)"
	@echo "  ...................................................................................."
	@echo "  github.issue.new : create issue in github"
	@echo "                   | $(GITHUB_ISSUE_LINK)/new"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
endef
