
受 [@tyrchen](https://github.com/tyrchen) 老师的 [code is law](https://zhuanlan.zhihu.com/p/36913380),
启发，本项目使用类 unix 环境下最基础的 `make` 作为构建工具, 遵循统一清晰的命名规范，以便在前后端各个子项目
间做到 `don't make me think` 的工作流程。 你可以在项目根目录执行 `make` 或 `make help` 查看帮助。

```text
  [valid launch commands]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  launch.mock : start server in mock(default) mode"
              | config locate in \"config/mock.exs\""
  ....................................................."
  launch.dev  : start phoenix server in development env"
              | config locate in \"config/dev.exs\""
  ....................................................."
  launch.prod : start phoenix server in produnction env"
              | config locate in \"config/prod.exs\""
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"


  [valid generators]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  gen.migration : generate migration fils
                | e.p  : gen.migration arg="add_name_to_users"
                | note : need to run "make migrate" later
  ..................................................................................
  gen.context   : generate a new context
                | e.p: make gen.context Accounts Credential credentials
                                        email:string:unique user_id:references:users
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


  [valid commit commands]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  commit : commit changes follow convention
         | convention: AngularJS's commit message convention
             | link: https://github.com/commitizen/cz-cli
             | link: https://github.com/angular/angular.js/blob/master/DEVELOPERS.md#-git-commit-guidelines
         | require: npm install
         | require: npm -v > 5.2 to use npx
             | link: https://medium.com/@maybekatz/introducing-npx-an-npm-package-runner-55f7d4bd282b
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


  [valid release commands]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  release        : release version by automatic CHANGELOG generation
                 | link: https://github.com/conventional-changelog/standard-version
                 | more:
                    | npm run release -- --prerelease
                    | npm run release -- --prerelease alpha
  .................................................................................
  release.master : release master branch
  .................................................................................
  release.dev    : release dev branch
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


  [valid deploy commands]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  deploy.dev  : pack & push code to aliyun for dev
               | need manually restart docker container on aliyun
  ...............................................................
  deploy.prod : pack & push  code to for produnction
               | need manually restart docker container on aliyun
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


  [valid console commands]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  console      : run iex
  ...................................
  console.dev  : run iex in dev env
  ...................................
  console.mock : run iex in mock env
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


  [valid test commands]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test             : run all the test then quit
  .....................................................
  test.watch       : run all the test in watch mode
  .....................................................
  test.watch.wip   : run @wip test in watch mode
  .....................................................
  test.db_reset    : reset test database
                   | needed when add new migration
  .....................................................
  test.report      : show test coverage status web page
  .....................................................
  test.report.text : show test coverage in terminal
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


  [valid dashboard commands]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  dashboard.apollo : graphql api status provide by apollo engine
                   | https://engine.apollographql.com/account/gh.mydearxym/services
  .................................................................................
  dashboard.aliyun : aliyun console
                   | https://home.console.aliyun.com/new
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


  [valid ci commands]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ci.build    : browse travis status
              | https://travis-ci.org/coderplanets/coderplanets_server
  ..........................................................................
  ci.coverage : browse test coveralls status
              | https://coveralls.io/github/coderplanets/coderplanets_server
  ..........................................................................
  ci.codecov  : browse test codecov status
              | https://codecov.io/gh/coderplanets/coderplanets_server
  ..........................................................................
  ci.doc      : browse doc coverage status
              | https://inch-ci.org/github/coderplanets/coderplanets_server
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


  [valid github commands]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  github.code      : browse source code in github
                   | https://github.com/coderplanets/coderplanets_server
  ....................................................................................
  github.doc       : browse repo docs in github
                   | https://github.com/coderplanets/coderplanets_server/tree/dev/docs
  ....................................................................................
  github.pr        : browse PRs in github
                   | https://github.com/coderplanets/coderplanets_server/pulls
  ....................................................................................
  github.issue     : browse issues in github
                   | https://github.com/coderplanets/coderplanets_server/issues
  ....................................................................................
  github.issue.new : create issue in github
                   | https://github.com/coderplanets/coderplanets_server/issues/new
  ....................................................................................
  github.app       : github oauth status (need login)
                   | https://github.com/settings/applications/689577
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

