defmodule GroupherServer.CMS.Delegate.Seeds.Categories do
  @doc """
  default categories seeds for general community
  """
  def get(:default) do
    [
      %{
        title: "pl",
        raw: "pl",
        index: 0
      },
      %{
        title: "frontend",
        raw: "frontend",
        index: 3
      },
      %{
        title: "backend",
        raw: "backend",
        index: 6
      },
      %{
        title: "mobile",
        raw: "mobile",
        index: 9
      },
      %{
        title: "ai",
        raw: "ai",
        index: 12
      },
      %{
        title: "ui",
        raw: "ui",
        index: 15
      },
      %{
        title: "blockchain",
        raw: "blockchain",
        index: 18
      },
      %{
        title: "city",
        raw: "city",
        index: 21
      },
      %{
        title: "other",
        raw: "other",
        index: 24
      }
    ]
  end
end
