defmodule MastaniServer.Accounts.Delegate.Billing do
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, get_config: 2]
  import ShortMaps

  alias MastaniServer.Repo
  alias MastaniServer.Accounts.{User, Purchase}
  alias Helper.ORM

  # ...

  def purchase_service(%User{} = user, key, value \\ true) do
    with {:ok, key} <- can_purchase?(user, key) do
      attrs = Map.put(%{user_id: user.id}, key, value)
      Purchase |> ORM.upsert_by([user_id: user.id], attrs)
    end
  end

  def has_purchased?(%User{} = user, key) do
    with {:ok, purchase} <- Purchase |> ORM.find_by(user_id: user.id),
         value <- purchase |> Map.get(key) do
      case value do
        true -> {:ok, key}
        false -> {:error, "AccountPurchase: not purchase"}
      end
    else
      nil -> {:error, "AccountPurchase: not purchase"}
      _ -> {:error, "AccountPurchase: not purchase"}
    end
  end

  defp can_purchase?(%User{} = user, key) do
    case key in valid_service do
      true -> {:ok, key}
      false -> {:error, "AccountPurchase: purchase invalid service"}
    end
  end

  defp valid_service do
    [:brainwash_free, :community_chart]
  end
end
