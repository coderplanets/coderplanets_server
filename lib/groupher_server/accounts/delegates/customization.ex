defmodule GroupherServer.Accounts.Delegate.Customization do
  @moduledoc """
  customization for user
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [map_atom_value: 2]
  import ShortMaps

  alias GroupherServer.Accounts
  alias Helper.ORM

  alias Accounts.Model.{Customization, User}
  alias Accounts.Delegate.Achievements

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
        {:ok, Map.merge(Customization.default(), customization)}

      {:error, _} ->
        {:ok, Customization.default()}
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
    with {:ok, ~m(achievement customization)a} <-
           ORM.find(User, user_id, preload: [:achievement, :customization]) do
      cur_c11n = extract_cur_c11n(customization)
      map = map |> map_atom_value(:string)

      valid? =
        map
        |> Map.keys()
        |> Enum.all?(&c11n_item_setable?(&1, achievement))

      case valid? do
        true ->
          map = Map.merge(cur_c11n, map)
          attrs = Map.merge(%{user_id: user.id}, map)

          attrs =
            if Map.has_key?(attrs, :theme),
              do: Map.merge(attrs, %{theme: downcase_theme(attrs.theme)}),
              else: attrs

          Customization |> ORM.upsert_by([user_id: user.id], attrs)

        false ->
          {:error, "AccountCustomization: invalid option or not member"}
      end
    end
  end

  def set_customization(%User{} = user, key, value \\ true) do
    with {:ok, %{achievement: achievement}} <- ORM.find(User, user.id, preload: :achievement) do
      case c11n_item_setable?(key, achievement) do
        true ->
          attrs = Map.put(%{user_id: user.id}, key, value)
          Customization |> ORM.upsert_by([user_id: user.id], attrs)

        false ->
          {:error, "AccountCustomization: invalid option or not member"}
      end
    end
  end

  defp extract_cur_c11n(nil), do: Customization.default()

  defp extract_cur_c11n(%Customization{} = customization) do
    customization = customization |> Map.from_struct() |> filter_nil_value

    Map.merge(Customization.default(), customization)
  end

  # defp c11n_item_setable?(:theme, %{
  # donate_member: donate_member,
  # senior_member: senior_member,
  # sponsor_member: sponsor_member
  # }) do
  # donate_member or senior_member or sponsor_member
  # end

  defp c11n_item_setable?(:theme, _achievement), do: true
  defp c11n_item_setable?(:banner_layout, _achievement), do: true
  defp c11n_item_setable?(:contents_layout, _achievement), do: true
  defp c11n_item_setable?(:content_divider, _achievement), do: true
  defp c11n_item_setable?(:content_hover, _achievement), do: true
  defp c11n_item_setable?(:mark_viewed, _achievement), do: true
  defp c11n_item_setable?(:display_density, _achievement), do: true
  defp c11n_item_setable?(:sidebar_layout, _achievement), do: true
  defp c11n_item_setable?(:sidebar_communities_index, _achievement), do: true
  # defp c11n_item_setable?(:brainwash_free, _achievement), do: true
  # defp c11n_item_setable?(:community_chart, _achievement), do: true

  defp c11n_item_setable?(_, _achievement), do: false

  defp filter_nil_value(map) do
    for {k, v} <- map, !is_nil(v), into: %{}, do: {k, v}
  end

  defp downcase_theme("SOLARIZEDDARK"), do: "solarizedDark"
  defp downcase_theme("solarizedDark"), do: "solarizedDark"
  defp downcase_theme("IRONGREEN"), do: "ironGreen"
  defp downcase_theme("ironGreen"), do: "ironGreen"
  defp downcase_theme(theme), do: String.downcase(theme)
end
