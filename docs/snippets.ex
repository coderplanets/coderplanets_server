

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
