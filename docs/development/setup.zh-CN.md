
### 初始化

使用 `make setup.help` 或 `make setup` 查看项目初始化命令。 在确保你知道用法后运
行 `make setup.run`, 该命令将自动帮你创建/迁移数据库表，安装依赖包等等。

```text

  [valid setup commands]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  setup.run   : setup the basic env for you, include 3-step
              | 1. mix ecto.setup # create/migrate tables in db
              | 2. mix deps.get   # for insall deps
              | 3. npm install    # for commit-msg linter
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

```


> 注意: 该命令不会帮你安装 Elixir/Erlang 环境。 请确保你的机器上有上述开发环境。
