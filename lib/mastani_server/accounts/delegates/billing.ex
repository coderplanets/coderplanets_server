defmodule MastaniServer.Accounts.Delegate.Billing do
  @moduledoc """
  user billings related
  """
  import Ecto.Query, warn: false

  alias Helper.ORM
  alias MastaniServer.Accounts.{Purchase, User}

  # ...
  def purchase_service(%User{} = _user, map) when map_size(map) == 0 do
    {:error, "AccountPurchase: invalid option or not purchased"}
  end

  def purchase_service(%User{} = user, map) when is_map(map) do
    valid? = map |> Map.keys() |> Enum.all?(&can_purchase?(user, &1, :boolean))

    case valid? do
      true ->
        attrs = Map.merge(%{user_id: user.id}, map)
        Purchase |> ORM.upsert_by([user_id: user.id], attrs)

      false ->
        {:error, "AccountCustomization: invalid option or not purchased"}
    end
  end

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

  defp can_purchase?(%User{} = user, key, :boolean) do
    case can_purchase?(%User{} = user, key) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp can_purchase?(%User{} = _user, key) do
    case key in valid_service do
      true -> {:ok, key}
      false -> {:error, "AccountPurchase: purchase invalid service"}
    end
  end

  defp valid_service do
    [:brainwash_free, :community_chart]
  end
end
