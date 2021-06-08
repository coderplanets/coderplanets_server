import GroupherServer.Support.Factory

alias GroupherServer.{CMS, Accounts}
alias Accounts.Model.User

{:ok, user} = db_insert(:user)
{:ok, post} = db_insert(:post)

Enum.reduce(1..15, [], fn _, acc ->
  unique_num = System.unique_integer([:positive, :monotonic])

  # {:ok, value} =
  #   CMS.create_comment(
  #     :post,
  #     :comment,
  #     post.id,
  #     %User{id: user.id},
  #     "#{Faker.Lorem.Shakespeare.king_richard_iii()} - #{unique_num}"
  #   )

  # acc ++ [value]
end)
