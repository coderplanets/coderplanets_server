import MastaniServer.Factory

alias MastaniServer.{CMS, Accounts}

{:ok, user} = db_insert(:user)
{:ok, post} = db_insert(:post)

Enum.reduce(1..15, [], fn _, acc ->
  {:ok, value} =
    CMS.create_comment(
      :post,
      :comment,
      post.id,
      %Accounts.User{id: user.id},
      Faker.Lorem.Shakespeare.king_richard_iii()
    )

  acc ++ [value]
end)
