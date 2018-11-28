defmodule MastaniServerWeb.Resolvers.Delivery do
  @moduledoc false

  alias Helper.Utils
  alias MastaniServer.Accounts.User
  alias MastaniServer.Delivery

  def mention_others(_root, args, %{context: %{cur_user: cur_user}}) do
    from_user_id = cur_user.id
    user_ids = args.user_ids |> Utils.pick_by(:id)

    Delivery.mention_others(%User{id: from_user_id}, user_ids, args)
  end

  def publish_system_notification(_root, args, %{context: %{cur_user: _}}) do
    Delivery.publish_system_notification(args)
  end
end
