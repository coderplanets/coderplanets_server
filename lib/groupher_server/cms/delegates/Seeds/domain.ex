defmodule GroupherServer.CMS.Delegate.Seeds.Domain do
  @moduledoc """
  seeds data for init, should be called ONLY in new database, like migration
  """

  import Ecto.Query, warn: false

  import GroupherServer.CMS.Delegate.Seeds.Helper,
    only: [
      threadify_communities: 2,
      tagfy_threads: 4,
      categorify_communities: 3,
      seed_bot: 0,
      seed_threads: 1,
      seed_categories_ifneed: 1
    ]

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.Community

  @oss_endpoint "https://cps-oss.oss-cn-shanghai.aliyuncs.com"

  # seed community
  @doc """
  seed community for home
  """
  def seed_community(:home) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "home"}),
         {:ok, bot} <- seed_bot(),
         {:ok, threads} <- seed_threads(:home) do
      args = %{
        title: "CoderPlanets",
        desc: "the most sexy community for developers, ever.",
        logo: "#{@oss_endpoint}/icons/cmd/keyboard_logo.png",
        raw: "home",
        user_id: bot.id
      }

      {:ok, community} = Community |> ORM.create(args)
      threadify_communities([community], threads.entries)
      tagfy_threads([community], threads.entries, bot, :home)

      {:ok, community}
      # home 不设置分类，比较特殊
    end
  end

  @doc """
  seed community for blackhole
  """
  def seed_community(:blackhole) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "blackhole"}),
         {:ok, bot} <- seed_bot(),
         {:ok, threads} <- seed_threads(:blackhole),
         {:ok, categories} <- seed_categories_ifneed(bot) do
      args = %{
        title: "黑洞",
        desc: "这里收录不适合出现在本站的内容。",
        logo: "#{@oss_endpoint}/icons/cmd/keyboard_logo.png",
        raw: "blackhole",
        user_id: bot.id
      }

      {:ok, community} = Community |> ORM.create(args)
      threadify_communities([community], threads.entries)
      tagfy_threads([community], threads.entries, bot, :blackhole)
      categorify_communities([community], categories, :feedback)

      {:ok, community}
    end
  end

  @doc """
  seed community for feedback
  """
  def seed_community(:feedback) do
    with {:error, _} <- ORM.find_by(Community, %{raw: "feedback"}),
         {:ok, bot} <- seed_bot(),
         {:ok, threads} <- seed_threads(:feedback),
         {:ok, categories} <- seed_categories_ifneed(bot) do
      args = %{
        title: "反馈与建议",
        desc: "关于本站的建议和反馈请发布在这里，谢谢。",
        logo: "#{@oss_endpoint}/icons/cmd/keyboard_logo.png",
        raw: "feedback",
        user_id: bot.id
      }

      {:ok, community} = Community |> ORM.create(args)
      threadify_communities([community], threads.entries)
      tagfy_threads([community], threads.entries, bot, :feedback)
      categorify_communities([community], categories, :feedback)

      {:ok, community}
      # home 不设置分类，比较特殊
    end
  end
end
