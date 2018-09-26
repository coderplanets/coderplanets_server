import MastaniServer.Support.Factory

alias MastaniServer.{CMS, Accounts}

{:ok, user} = db_insert(:user)
{:ok, post} = db_insert(:post)

Enum.reduce(1..15, [], fn _, acc ->
  unique_num = System.unique_integer([:positive, :monotonic])

  {:ok, value} =
    CMS.create_comment(
      :post,
      :comment,
      post.id,
      %Accounts.User{id: user.id},
      "#{Faker.Lorem.Shakespeare.king_richard_iii()} - #{unique_num}"
    )

  acc ++ [value]
end)
