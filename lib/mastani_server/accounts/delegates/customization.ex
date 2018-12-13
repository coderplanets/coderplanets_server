defmodule MastaniServer.Accounts.Delegate.Customization do
  @moduledoc """
  customization for user
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [get_config: 2, map_atom_value: 2]

  alias Helper.ORM
  alias MastaniServer.Accounts

  alias Accounts.{User, Customization}
  alias Accounts.Delegate.Achievements

  @default_customization get_config(:customization, :all) |> Enum.into(%{})

  def upgrade_by_plan(%User{} = user, :donate) do
    Achievements.set_member(user, :donate)
  end

  def upgrade_by_plan(%User{} = user, :senior) do
    Achievements.set_member(user, :senior)
  end

  def upgrade_by_plan(%User{} = user, :sponsor) do
    Achievements.set_member(user, :sponsor)
  end

  def upgrade_by_plan(%User{} = _user, _plan) do
    {:error, "no such plan"}
  end

  @doc """
  get user's customization, if not have, return default customization
  """
  def get_customization(%User{id: user_id}) do
    case ORM.find_by(Customization, user_id: user_id) do
      {:ok, customization} ->
        customization = customization |> Map.from_struct() |> filter_nil_value
        {:ok, Map.merge(@default_customization, customization)}

      {:error, _} ->
        {:ok, @default_customization}
    end
  end

  @doc """
  add custom setting to user
  """
  # for map_size
  # see https://stackoverflow.com/questions/33248816/pattern-match-function-against-empty-map

  def set_customization(%User{} = _user, map) when map_size(map) == 0 do
    {:error, "AccountCustomization: invalid option or not member"}
  end

  def set_customization(%User{id: user_id} = user, map) when is_map(map) do
    with {:ok, %{achievement: achievement}} <- ORM.find(User, user_id, preload: :achievement) do
      map = map |> map_atom_value(:string)

      valid? =
        map
        |> Map.keys()
        |> Enum.all?(&c11n_item_require?(&1, achievement))

      case valid? do
        true ->
          attrs = Map.merge(%{user_id: user.id}, map)
          Customization |> ORM.upsert_by([user_id: user.id], attrs)

        false ->
          {:error, "AccountCustomization: invalid option or not member"}
      end
    end
  end

  def set_customization(%User{} = user, key, value \\ true) do
    with {:ok, %{achievement: achievement}} <- ORM.find(User, user.id, preload: :achievement) do
      case c11n_item_require?(key, achievement) do
        true ->
          attrs = Map.put(%{user_id: user.id}, key, value)
          Customization |> ORM.upsert_by([user_id: user.id], attrs)

        false ->
          {:error, "AccountCustomization: invalid option or not member"}
      end
    end
  end

  defp c11n_item_require?(:theme, %{
         donate_member: donate_member,
         senior_member: senior_member,
         sponsor_member: sponsor_member
       }) do
    donate_member or senior_member or sponsor_member
  end

  defp c11n_item_require?(:banner_layout, _), do: true
  defp c11n_item_require?(:contents_layout, _), do: true
  defp c11n_item_require?(:content_divider, _), do: true
  defp c11n_item_require?(:mark_viewed, _), do: true
  defp c11n_item_require?(:display_density, _), do: true
  defp c11n_item_require?(:sidebar_layout, _), do: true
  defp c11n_item_require?(:sidebar_communities_index, _), do: true
  # defp c11n_item_require?(:brainwash_free, _), do: true
  # defp c11n_item_require?(:community_chart, _), do: true

  defp c11n_item_require?(_, _), do: false

  defp filter_nil_value(map) do
    for {k, v} <- map, !is_nil(v), into: %{}, do: {k, v}
  end
end
