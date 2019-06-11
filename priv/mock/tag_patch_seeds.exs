alias GroupherServer.CMS
alias GroupherServer.CMS.Delegate.SeedsConfig
alias GroupherServer.CMS.Delegate.Seeds
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
    thread: :repo,
    topic: "repos"
  },
  %{
    title: "tuts",
    color: :purple,
    thread: :repo,
    topic: "repos"
  }
]

Enum.each(patch_communities, fn raw ->
  {:ok, community} = ORM.find_by(CMS.Community, %{raw: raw})

  case community.raw not in ["cps-support"] do
    true ->
      # create_tags(community, :repo)
      IO.inspect(community.raw, label: "patching community")

      Enum.each(patch_tags, fn attr ->
        {:ok, _} = CMS.create_tag(community, :repo, attr, bot)
      end)

    false ->
      false
  end
end)
