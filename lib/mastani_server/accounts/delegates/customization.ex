defmodule MastaniServer.Accounts.Delegate.Customization do
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, get_config: 2]
  import ShortMaps

  alias MastaniServer.Repo
  alias MastaniServer.Accounts
  alias MastaniServer.Accounts.{User, Bill, Customization}
  alias Helper.ORM
  # ...
  # TODO: Constants

  def add_custom_setting(%User{} = user, key, value \\ true) do
    with {:ok, key} <- can_set?(user, key) do
      attrs = Map.put(%{user_id: user.id}, key, value)
      Customization |> ORM.upsert_by([user_id: user.id], attrs)
    end
  end

  def can_set?(%User{} = user, key) do
    cond do
      key in valid_custom_items(:free) ->
        {:ok, key}

      key in valid_custom_items(:advance) ->
        Accounts.has_purchased?(user, key)

      true ->
        {:error, "AccountCustomization: invalid option"}
    end
  end

  @doc """
  # theme           --  user can set a default theme
  # sidebar_layout  --  user can arrange subscribed community index
  """
  def valid_custom_items(:free) do
    [:theme, :sidebar_layout]
  end

  @doc """
  # :brainwash_free    --  ads free
  # ::community_chart  --  user can access comunity charts
  """
  def valid_custom_items(:advance) do
    # NOTE: :brainwash_free aka. "ads_free"
    # use brainwash to avoid brower-block-plugins
    [:brainwash_free, :community_chart]
  end
end
