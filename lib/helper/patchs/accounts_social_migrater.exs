# migrate old social fields in account table to user_socials table
alias Helper.ORM

alias GroupherServer.Accounts.Model.{User, Social}
alias Helper.Patch.SocialMigrater

defmodule Helper.Patch.SocialMigrater do
  def insert_social_records(id, map) when map_size(map) == 0, do: IO.puts("pass robot user")

  def insert_social_records(id, attrs) do
    attrs = Map.merge(%{user_id: id}, attrs)

    Social
    |> ORM.upsert_by([user_id: id], attrs)
    |> IO.inspect(label: "result")
  end
end

filter = %{page: 1, size: 320}
{:ok, accounts} = User |> ORM.find_all(filter)

social_keys = [
  :qq,
  :weibo,
  :weichat,
  :github,
  :zhihu,
  :douban,
  :twitter,
  :facebook,
  :dribble,
  :instagram,
  :pinterest,
  :huaban
]

Enum.each(accounts.entries, fn user ->
  social_attrs =
    user
    |> Map.take(social_keys)
    |> Enum.reject(fn {k, v} -> is_nil(v) end)
    |> Map.new()

  SocialMigrater.insert_social_records(user.id, social_attrs)
end)
