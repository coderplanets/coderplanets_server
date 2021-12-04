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
        raw: "cper",
        index: 5
      }
      # %{
      #   title: "设置",
      #   raw: "setting",
      #   index: 6
      # }
    ]
  end

  def get(:blackhole) do
    [
      %{
        title: "帖子",
        raw: "post",
        index: 1
      },
      %{
        title: "账户",
        raw: "account",
        index: 2
      },
      %{
        title: "工作",
        raw: "job",
        index: 3
      },
      %{
        title: "雷达",
        raw: "radar",
        index: 4
      },
      %{
        title: "博客",
        raw: "blog",
        index: 5
      },
      %{
        title: "作品",
        raw: "works",
        index: 6
      }
    ]
  end

  def get(:feedback) do
    [
      %{
        title: "帖子",
        raw: "post",
        index: 1
      },
      %{
        title: "看板",
        raw: "kanban",
        index: 2
      },
      %{
        title: "分布",
        raw: "map",
        index: 3
      }
    ]
  end

  def get(:makers) do
    [
      %{
        title: "帖子",
        raw: "post",
        index: 1
      },
      %{
        title: "作品",
        raw: "works",
        index: 2
      },
      %{
        title: "访谈",
        raw: "interview",
        index: 3
      }
      # %{
      #   title: "101",
      #   raw: "101",
      #   index: 4
      # },
    ]
  end

  def get(:adwall) do
    [
      %{
        title: "帖子",
        raw: "post",
        index: 1
      }
    ]
  end

  def get(:ask) do
    [
      %{
        title: "帖子",
        raw: "post",
        index: 1
      }
    ]
  end

  def get(:pl), do: get(:framework)

  # 语言，编程框架等
  def get(:framework) do
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
      # %{
      #   title: "101",
      #   raw: "tut",
      #   index: 4
      # },
      # %{
      #   title: "awesome",
      #   raw: "awesome",
      #   index: 5
      # },
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
        raw: "map",
        index: 8
      }
      # %{
      #   title: "设置",
      #   raw: "setting",
      #   index: 8
      # }
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
