alias GroupherServer.CMS

alias CMS.Model.Community
alias GroupherServer.CMS.Delegate.{Seeds, SeedsConfig}

alias Helper.ORM

patch_communities =
  SeedsConfig.communities(:pl) ++
    SeedsConfig.communities(:framework) ++
    SeedsConfig.communities(:ui) ++
    SeedsConfig.communities(:blockchain) ++
    SeedsConfig.communities(:editor) ++
    SeedsConfig.communities(:database) ++ SeedsConfig.communities(:devops)

{:ok, bot} = Seeds.seed_bot()

patch_tags = [
  %{
    title: "docs",
    color: :blue,
    thread: :repo
  },
  %{
    title: "tuts",
    color: :purple,
    thread: :repo
  }
]

Enum.each(patch_communities, fn raw ->
  {:ok, community} = ORM.find_by(Community, %{raw: raw})

  case community.raw not in ["cps-support"] do
    true ->
      # create_tags(community, :repo)
      Enum.each(patch_tags, fn attr ->
        {:ok, _} = CMS.create_tag(community, :repo, attr, bot)
      end)

    false ->
      false
  end
end)
