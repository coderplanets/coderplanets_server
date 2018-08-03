
BELONG = "coderplanets"
REPO = "coderplanets_server"

CI_BUILD_LINK = "https://travis-ci.org/$(BELONG)/$(REPO)"
CI_COVER_LINK = "https://coveralls.io/github/$(BELONG)/$(REPO)"
CI_DOC_LINK = "https://inch-ci.org/github/$(BELONG)/$(REPO)"

GITHUB_CODE_LINK = "https://github.com/$(BELONG)/$(REPO)"
GITHUB_DOC_LINK = "https://github.com/$(BELONG)/$(REPO)/tree/dev/docs"
GITHUB_PR_LINK = "https://github.com/$(BELONG)/$(REPO)/pulls"
GITHUB_ISSUE_LINK = "https://github.com/$(BELONG)/$(REPO)/issues"

ci:
	@echo "\n"
	@echo "  [valid ci commands]"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	@echo "  ci.build : browse travis status"
	@echo "           | $(CI_BUILD_LINK)"
	@echo "  ........................................"
	@echo "  ci.cover : browse test coveralls status"
	@echo "           | $(CI_COVER_LINK)"
	@echo "  ........................................"
	@echo "  ci.doc   : browse doc coverage status"
	@echo "           | $(CI_DOC_LINK)"
	@echo "\n"

github:
	@echo "\n"
	@echo "  [valid github commands]"
	@echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	@echo "  github.code      : browse source code in github"
	@echo "                   | $(GITHUB_CODE_LINK)"
	@echo "  ........................................"
	@echo "  github.doc       : browse repo docs in github"
	@echo "                   | $(GITHUB_DOC_LINK)"
	@echo "  ........................................"
	@echo "  github.pr        : browse PRs in github"
	@echo "                   | $(GITHUB_PR_LINK)"
	@echo "  ........................................"
	@echo "  github.issue     : browse issues in github"
	@echo "                   | $(GITHUB_ISSUE_LINK)"
	@echo "  ........................................"
	@echo "  github.issue.new : create issue in github"
	@echo "                   | $(GITHUB_ISSUE_LINK)/new"
	@echo "\n"

# ci helpers
ci.build:
	open "$(CI_BUILD_LINK)"
ci.cover:
	open "$(CI_COVER_LINK)"
ci.doc:
	open "$(CI_DOC_LINK)"

# github helpers
github.code:
	open "$(GITHUB_CODE_LINK)"
github.doc:
	open "$(GITHUB_DOC_LINK)"
github.pr:
	open "$(GITHUB_PR_LINK)"
github.issue:
	open "$(GITHUB_ISSUE_LINK)"
github.issue.new:
	open "$(GITHUB_ISSUE_LINK)/new"
