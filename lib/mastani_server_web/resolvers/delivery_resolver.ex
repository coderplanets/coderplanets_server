defmodule MastaniServerWeb.Resolvers.Delivery do
  @moduledoc false

  alias MastaniServer.Delivery
  alias MastaniServer.Accounts.User
  # alias Helper.ORM

  def mention_someone(_root, args, %{context: %{cur_user: cur_user}}) do
    from_user_id = cur_user.id
    to_user_id = args.user_id

    Delivery.mention_someone(%User{id: from_user_id}, %User{id: to_user_id}, args)
  end
end
