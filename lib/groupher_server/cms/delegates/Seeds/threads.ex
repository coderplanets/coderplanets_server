defmodule GroupherServer.CMS.Delegate.Seeds.Threads do
  def get(:home) do
    [
      %{
        title: "帖子",
        raw: "post",
        index: 1
      },
      %{
        title: "雷达",
        raw: "radar",
        index: 2
      },
      %{
        title: "博客",
        raw: "blog",
        index: 3
      },
      %{
        title: "工作",
        raw: "job",
        index: 4
      },
      %{
        title: "CPer",
        raw: "users",
        index: 5
      },
      %{
        title: "设置",
        raw: "setting",
        index: 6
      }
    ]
  end

  # 语言，编程框架等
  def get(:lang) do
    [
      %{
        title: "帖子",
        raw: "post",
        index: 1
      },
      %{
        title: "雷达",
        raw: "radar",
        index: 2
      },
      %{
        title: "博客",
        raw: "blog",
        index: 3
      },
      %{
        title: "101",
        raw: "tut",
        index: 4
      },
      %{
        title: "awesome",
        raw: "awesome",
        index: 5
      },
      %{
        title: "作品",
        raw: "works",
        index: 6
      },
      %{
        title: "工作",
        raw: "job",
        index: 7
      },
      %{
        title: "分布",
        raw: "users",
        index: 8
      },
      %{
        title: "设置",
        raw: "setting",
        index: 8
      }
    ]
  end

  def get(:city) do
    [
      %{
        title: "帖子",
        raw: "post",
        index: 1
      },
      %{
        title: "团队",
        raw: "team",
        index: 2
      },
      %{
        title: "工作",
        raw: "job",
        index: 3
      }
    ]
  end

  def get(:users), do: []
end
