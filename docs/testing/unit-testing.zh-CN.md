
### 单元测试

单元测试部分全部位于 `test/groupher_server/` 目录下, 按照接口的 Context 分为

```text
accounts   billing    cms        delivery   logs       seeds      statistics
```

> Phoenix 使用 ExUnit(link) 作为测试模块，测试文件必须以 '_test.exs' 作为结尾，否则会被忽略。

#### 运行测试

在项目根目录执行 `make test` 即可运行所有测试, 你也可以使用 `make test.watch` 或
`make test.watch.wip` 以 watch mode 运行全部或其中一部分测试。 更多命令可以使用
`make test.help` 查看: 

```text

  [valid test commands]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test             : run all the test then quit
  .....................................................
  test.watch       : run all the test in watch mode
  .....................................................
  test.watch.wip   : run @wip test in watch mode
  .....................................................
  test.watch.wip2  : shortcut for lots of @wip around
  .....................................................
  test.watch.bug  : sometimes fails for unkown reason
  .....................................................
  test.report      : show test coverage status web page
  .....................................................
  test.report.text : show test coverage in terminal
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

```

#### Helper 函数

以一个实际例子作为说明: 

```elixir
defmodule GroupherServer.Test.CMS do
  use GroupherServer.TestTools

  alias GroupherServer.Accounts.User
  alias GroupherServer.CMS
  alias CMS.Community

  alias Helper.{Certification, ORM}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, category} = db_insert(:category)

    {:ok, ~m(user community category)a}
  end

  describe "[cms tag]" do
    test "create tag with valid data", ~m(community user)a do
      valid_attrs = mock_attrs(:tag)

      {:ok, tag} = CMS.create_tag(community, :post, valid_attrs, %User{id: user.id})
      assert tag.title == valid_attrs.title
    end
  end
  # ....
end
```

1. 每个测试开头引入的 TestTools 包含常用的测试模块，函数等

```elixir
use GroupherServer.TestTools
```

2. setup 中可以存放所有文件中都需要初始化的一些数据

3. 这里测试的都是 `lib/groupher_server` 下的模块，不涉及 Graphql

4. 更多的技巧你可以参照文档或现有的测试用例，通常它们都浅显易懂。





