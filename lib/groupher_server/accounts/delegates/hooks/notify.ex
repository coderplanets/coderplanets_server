defmodule GroupherServer.Accounts.Delegate.Hooks.Notify do
  @moduledoc """
  notify hooks, for upvote, collect, comment, reply
  """
  alias GroupherServer.{Accounts, Delivery}
  alias Accounts.Model.User

  # 发布评论是特殊情况，单独处理
  def handle(:follow, %User{} = user, %User{} = from_user) do
    notify_attrs = %{
      action: :follow,
      user_id: user.id
    }

    Delivery.send(:notify, notify_attrs, from_user)
  end

  def handle(:undo, :follow, %User{} = user, %User{} = from_user) do
    notify_attrs = %{
      action: :follow,
      user_id: user.id
    }

    Delivery.revoke(:notify, notify_attrs, from_user)
  end
end
