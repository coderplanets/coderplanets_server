defmodule GroupherServer.CMS.Delegate.Seeds.Categories do
  @doc """
  default categories seeds for general community
  """
  def get() do
    [
      %{
        title: "编程语言",
        raw: "pl",
        index: 0
      },
      %{
        title: "框架 & 库",
        raw: "framework",
        index: 1
      },
      %{
        title: "数据库",
        raw: "database",
        index: 2
      },
      %{
        title: "devops",
        raw: "devops",
        index: 3
      },
      %{
        title: "开发工具",
        raw: "tools",
        index: 4
      },
      %{
        title: "城市",
        raw: "city",
        index: 5
      },
      %{
        title: "人工智能",
        raw: "ai",
        index: 6
      },
      %{
        title: "作品",
        raw: "works",
        index: 7
      },
      %{
        # blackhole, Feedback, dev
        title: "站务",
        raw: "feedback",
        index: 8
      },
      %{
        # Makers, Adwall, Outwork
        title: "其他",
        raw: "others",
        index: 9
      }
    ]
  end
end
