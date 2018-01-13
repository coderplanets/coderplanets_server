

defp find_target(target, id) do
  case Repo.get(target, id) do
    nil ->
      {:error, "#{target} id #{id} not found."}

    target ->
      {:ok, target}
  end
end


defp which_join_table(react, type) when is_type_valid(type) and is_react_valid(react),
  do: {:ok, "users_#{type}s_#{react}s"}

defp which_join_table(react, type),
  do: {:error, "#{react} not supported or #{type} (join table) not found"}

# star, collect, watch, up, down ...
# manipulate join-table is fine, see: https://github.com/elixir-ecto/ecto/issues/2366
def add_reaction(react, type, id, user_id) do
  with {:ok, config} <- which_part(type),
       {:ok, join_table} <- which_join_table(react, type),
       {:ok, target} <- find_target(config.model, id),
       {:ok, user} <- Accounts.find_user(user_id) do
    query = Map.put(%{}, config.field, target.id) |> Map.put("user_id", user.id)

    case Repo.insert_all(join_table, [query], on_conflict: :nothing) do
      {_, nil} -> {:ok, target}
    end
  else
    {:error, reason} ->
      {:error, reason}
  end
end


# join table is fine, see https://github.com/elixir-ecto/ecto/issues/2366
def comment_post(post_id, body) do
  # TODO: use Multi to do it
  with {:ok, post} <- find_content(Post, post_id),
       {:ok, comment} <- create_comment(%{body: body}) do
    # ugly hack, see https://elixirforum.com/t/put-assoc-in-many-to-many-crash-the-server/11409/3
    case Repo.insert_all("cms_posts_comments", [%{post_id: post.id, comment_id: comment.id}]) do
      {_, nil} -> {:ok, comment}
    end
  else
    {:error, reason} ->
      {:error, reason}
  end
end


def back_up(part, react, filters) when valid_reaction(part, react) do
  with {:ok, action} <- match_action(part, react) do
    # query = action.target |> Helper.filter_pack(filters)
    query0 =
      from(
        p in Post,
        left_join: s in assoc(p, :stars),
        group_by: p.id,
        # select: p,
        # select: {p, %{counts: fragment("count(?) as counts", s.id)}}
        select: [p, %{counts: fragment("count(?) as counts", s.id)}]
      )

    # query = query0 |> order_by([desc: fragment("counts")])

    query =
      Post
      |> join(:left, [p], s in assoc(p, :stars))
      |> order_by([p, s], desc: fragment("count(?)", s.id))
      |> group_by([p], p.id)
      |> select([p], p)

    # IO.inspect Repo.all(query), label: "fuck bb"
    {:ok, Repo.all(query)}
  end
end
