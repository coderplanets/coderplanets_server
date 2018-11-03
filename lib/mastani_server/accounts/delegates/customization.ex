defmodule MastaniServer.Accounts.Delegate.Customization do
  @moduledoc """
  customization for user
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [get_config: 2, map_atom_value: 2]

  alias Helper.ORM
  alias MastaniServer.Accounts
  alias MastaniServer.Accounts.{User, Customization}

  @default_customization get_config(:customization, :all) |> Enum.into(%{})

  @doc """
  get user's customization, if not have, return default customization
  """
  def get_customization(%User{id: user_id}) do
    case ORM.find_by(Customization, user_id: user_id) do
      {:ok, customization} -> {:ok, Map.merge(@default_customization, customization)}
      {:error, _} -> {:ok, @default_customization}
    end
  end

  @doc """
  add custom setting to user
  """
  # for map_size
  # see https://stackoverflow.com/questions/33248816/pattern-match-function-against-empty-map
  def set_customization(%User{} = _user, map) when map_size(map) == 0 do
    {:error, "AccountCustomization: invalid option or not purchased"}
  end

  def set_customization(%User{} = user, map) when is_map(map) do
    map = map |> map_atom_value(:string)

    valid? =
      map
      |> Map.keys()
      |> Enum.all?(&can_set?(user, &1, :boolean))

    case valid? do
      true ->
        attrs = Map.merge(%{user_id: user.id}, map)
        Customization |> ORM.upsert_by([user_id: user.id], attrs)

      false ->
        {:error, "AccountCustomization: invalid option or not purchased"}
    end
  end

  def set_customization(%User{} = user, key, value \\ true) do
    with {:ok, key} <- can_set?(user, key) do
      attrs = Map.put(%{user_id: user.id}, key, value)
      Customization |> ORM.upsert_by([user_id: user.id], attrs)
    end
  end

  defp can_set?(%User{} = user, key, :boolean) do
    case can_set?(%User{} = user, key) do
      {:ok, _} -> true
      {:error, _} -> false
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
    [
      :sidebar_layout,
      :banner_layout,
      :contents_layout,
      :content_divider,
      :mark_viewed,
      :display_density
    ]
  end

  @doc """
  # :brainwash_free    --  ads free
  # ::community_chart  --  user can access comunity charts
  """
  def valid_custom_items(:advance) do
    # NOTE: :brainwash_free aka. "ads_free"
    # use brainwash to avoid brower-block-plugins
    [:theme, :brainwash_free, :community_chart]
  end
end
