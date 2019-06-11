
### GraphQL 接口测试

GraphQL 接口的测试部分全部位于 `test/groupher_server_web/` 目录下, 按照接口的用途
又分为 `query` 和 `mutation` 目录。

以 `query` 测试为例, `query` 目录下按照项目的 `context` 分为: 

```text
accounts   billing    cms    statistics
```

每个目录测试相应的 context 模块。

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
defmodule GroupherServer.Test.Query.CMS.Basic do
  use GroupherServer.TestTools

  alias GroupherServer.Accounts.User
  alias GroupherServer.CMS
  alias CMS.{Community, Thread, Category}

  setup do
    guest_conn = simu_conn(:guest)
    {:ok, community} = db_insert(:community)
    {:ok, user} = db_insert(:user)

    {:ok, ~m(guest_conn community user)a}
  end

  describe "[cms communities]" do
    @query """
    query($id: ID) {
      community(id: $id) {
        id
        title
        threads {
          id
          raw
          index
        }
      }
    }
    """
    test "guest use get community threads with default asc sort index",
         ~m(guest_conn community)a do
      {:ok, threads} = db_insert_multi(:thread, 5)

      Enum.map(threads, fn t ->
        CMS.set_thread(%Community{id: community.id}, %Thread{id: t.id})
      end)

      variables = %{id: community.id}
      results = guest_conn |> query_result(@query, variables, "community")

      first_idx = results["threads"] |> List.first() |> Map.get("index")
      last_idx = results["threads"] |> List.last() |> Map.get("index")

      assert first_idx < last_idx
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

3. `simu_conn` 和 `db_insert` 可以分别模拟 http 连接和 mock 数据。

4. 更多的技巧你可以参照文档或现有的测试用例，通常它们都浅显易懂。



