# TODO: remove later
# import GroupherServer.Support.Factory

alias Helper.ORM
alias GroupherServer.CMS
alias GroupherServer.Accounts

alias CMS.Model.{Community, Post, Embeds}
alias Accounts.Model.User

default_meta = Embeds.ArticleMeta.default_meta()

# {:ok, home_community} = ORM.find_by(Community, %{raw: "home"})
# {:ok, bot} = ORM.find(User, 1)

# ret = CMS.update_community_count_field(home_community, bot.id, :subscribers_count, :inc)
# IO.inspect(ret, label: "after")
{:ok, all_posts} = ORM.find_all(Post, %{page: 1, size: 300})
# IO.inspect(all_community.total_count, laebl: "all")

all_posts.entries
|> Enum.each(fn post ->
  IO.inspect(post.title, label: "each")
  IO.inspect(post.id, label: "each id")
  cur_updated_at = post.updated_at
  # IO.inspect(cur_updated_at, label: "curent cur_updated_at")

  with {:ok, post} <- ORM.update_meta(post, default_meta) do
    {:ok, _} = ORM.update(post, %{updated_at: cur_updated_at, actived_at: cur_updated_at})
  end
end)

# {:ok, post} = ORM.find_by(Post, %{id: "200"})
# IO.inspect(post.updated_at)
# {:ok, _} = ORM.update(post, %{updated_at: ~U[2019-05-14 00:57:56.000000Z]})
# IO.inspect(all_community.total_count, laebl: "all")
