OS := ${shell uname}

.PHONY: test publish

BELONG = "coderplanets"
REPO = "coderplanets_server"

DASHBOARD_APOLLO_LINK = "https://engine.apollographql.com/account/gh.mydearxym/services"
DASHBOARD_ALIYUN_LINK = "https://home.console.aliyun.com/new"

CI_BUILD_LINK = "https://travis-ci.org/$(BELONG)/$(REPO)"
CI_COVERAGE_LINK = "https://coveralls.io/github/$(BELONG)/$(REPO)"
CI_CODECOV_LINK = "https://codecov.io/gh/$(BELONG)/$(REPO)"
CI_DOC_LINK = "https://inch-ci.org/github/$(BELONG)/$(REPO)"

GITHUB_CODE_LINK = "https://github.com/$(BELONG)/$(REPO)"
GITHUB_DOC_LINK = "https://github.com/$(BELONG)/$(REPO)/tree/dev/docs"
GITHUB_PR_LINK = "https://github.com/$(BELONG)/$(REPO)/pulls"
GITHUB_ISSUE_LINK = "https://github.com/$(BELONG)/$(REPO)/issues"
GITHUB_APP_LINK = "https://github.com/settings/applications/689577"

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

define commit.help
	@echo "\n"
	@echo "  [valid commit commands]"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	@echo "  commit : commit changes follow convention"
	@echo "         | convention: AngularJS's commit message convention"
	@echo "             | link: https://github.com/commitizen/cz-cli"
	@echo "             | link: https://github.com/angular/angular.js/blob/master/DEVELOPERS.md#-git-commit-guidelines"
	@echo "         | require: npm install"
	@echo "         | require: npm -v > 5.2 to use npx"
	@echo "             | link: https://medium.com/@maybekatz/introducing-npx-an-npm-package-runner-55f7d4bd282b"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
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
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	@echo "  ci.build    : browse travis status"
	@echo "              | $(CI_BUILD_LINK)"
	@echo "  .........................................................................."
	@echo "  ci.coverage : browse test coveralls status"
	@echo "              | $(CI_COVERAGE_LINK)"
	@echo "  .........................................................................."
	@echo "  ci.codecov  : browse test codecov status"
	@echo "              | $(CI_CODECOV_LINK)"
	@echo "  .........................................................................."
	@echo "  ci.doc      : browse doc coverage status"
	@echo "              | $(CI_DOC_LINK)"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
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
	@echo "  ...................................................................................."
	@echo "  github.app       : github oauth status (need login)"
	@echo "                   | $(GITHUB_APP_LINK)"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
endef
