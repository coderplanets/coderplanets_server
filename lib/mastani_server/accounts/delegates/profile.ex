defmodule MastaniServer.Accounts.Delegate.Profile do
  @moduledoc """
  accounts profile
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, get_config: 2]
  import ShortMaps

  alias MastaniServer.Accounts
  alias Helper.{Guardian, ORM, QueryBuilder, RadarSearch}
  alias MastaniServer.Accounts.{Achievement, GithubUser, User}
  alias MastaniServer.{CMS, Repo}

  alias Ecto.Multi

  @default_subscribed_communities get_config(:general, :default_subscribed_communities)

  @doc """
  update user's profile
  """
  def update_profile(%User{} = user, attrs \\ %{}) do
    changeset =
      user
      |> Ecto.Changeset.change(attrs)

    changeset =
      cond do
        Map.has_key?(attrs, :education_backgrounds) ->
          changeset
          |> Ecto.Changeset.put_embed(:education_backgrounds, attrs.education_backgrounds)

        Map.has_key?(attrs, :work_backgrounds) ->
          changeset
          |> Ecto.Changeset.put_embed(:work_backgrounds, attrs.work_backgrounds)

        Map.has_key?(attrs, :other_embeds) ->
          changeset
          |> Ecto.Changeset.put_embed(:other_embeds, attrs.other_embeds)

        true ->
          changeset
      end

    changeset |> User.update_changeset(attrs) |> Repo.update()
  end

  @doc """
  update geo info for user, include geo_city & remote ip
  """
  def update_geo(%User{geo_city: geo_city} = user, remote_ip) when is_nil(geo_city) do
    case RadarSearch.locate_city(remote_ip) do
      {:ok, city} ->
        update_profile(user, %{geo_city: city, remote_ip: remote_ip})

      {:error, _} ->
        update_profile(user, %{remote_ip: remote_ip})
        {:ok, "pass"}
    end
  end

  def update_geo(%User{} = user, remote_ip), do: update_profile(user, %{remote_ip: remote_ip})
  def update_geo(_user, _remote_ip), do: {:ok, "pass"}

  @doc """
  github_signin steps:
  ------------------
  step 0: get access_token is enough, even profile is not need?
  step 1: check is access_token valid or not, think use a Middleware
  step 2.1: if access_token's github_id exsit, then login
  step 2.2: if access_token's github_id not exsit, then signup
  step 3: return mastani token
  """
  def github_signin(github_user) do
    case ORM.find_by(GithubUser, github_id: to_string(github_user["id"])) do
      {:ok, g_user} ->
        {:ok, user} = ORM.find(User, g_user.user_id)
        token_info(user)

      {:error, _} ->
        register_github_user(github_user)
    end
  end

  @doc """
  get default subscribed communities for unlogin user
  """
  def default_subscribed_communities(%{page: _, size: _} = filter) do
    filter = Map.merge(filter, %{size: @default_subscribed_communities, category: "pl"})

    with {:ok, home_community} <- ORM.find_by(CMS.Community, raw: "home"),
         {:ok, paged_communities} <- ORM.find_all(CMS.Community, filter) do
      %{
        entries: paged_communities.entries ++ [home_community],
        page_number: paged_communities.page_number,
        page_size: paged_communities.page_size,
        total_count: paged_communities.total_count + 1,
        total_pages: paged_communities.total_pages
      }
      |> done()
    else
      _error ->
        %{
          entries: [],
          page_number: 1,
          page_size: @default_subscribed_communities,
          total_count: 0,
          total_pages: 1
        }
        |> done()
    end
  end

  @doc """
  get users subscribed communities
  """
  def subscribed_communities(%User{id: id} = user, %{page: page, size: size} = filter) do
    filter = filter |> Map.delete(:first)
    # TODO: merge customed index
    CMS.CommunitySubscriber
    |> where([c], c.user_id == ^id)
    |> join(:inner, [c], cc in assoc(c, :community))
    |> select([c, cc], cc)
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginater(~m(page size)a)
    |> sort_communities(user)
    |> done()
  end

  # sort by users sort customization
  defp sort_communities(paged_communities, user) do
    with {:ok, customization} <- Accounts.get_customization(user) do
      case Enum.empty?(customization.sidebar_communities_index) do
        true ->
          paged_communities

        false ->
          entries =
            Enum.map(paged_communities.entries, fn c ->
              index = Map.get(customization.sidebar_communities_index, c.raw, 100_000)
              %{c | index: index}
            end)

          %{paged_communities | entries: entries}
      end
    end
  end

  defp register_github_user(github_profile) do
    Multi.new()
    |> Multi.run(:create_user, fn _, _ ->
      create_user(github_profile, :github)
    end)
    |> Multi.run(:create_profile, fn _, %{create_user: user} ->
      create_profile(user, github_profile, :github)
    end)
    |> Multi.run(:init_achievement, fn _, %{create_user: user} ->
      Achievement |> ORM.upsert_by([user_id: user.id], %{user_id: user.id})
    end)
    |> Repo.transaction()
    |> register_github_result
  end

  defp register_github_result({:ok, %{create_user: user}}) do
    token_info(user)
  end

  defp register_github_result({:error, :create_user, _result, _steps}),
    do: {:error, "Accounts create_user internal error"}

  defp register_github_result({:error, :create_profile, _result, _steps}),
    do: {:error, "Accounts create_profile internal error"}

  defp token_info(%User{} = user) do
    with {:ok, token, _info} <- Guardian.jwt_encode(user) do
      {:ok, %{token: token, user: user}}
    end
  end

  defp create_user(profile, :github) do
    attrs = %{
      nickname: profile["login"],
      github: "https://github.com/#{profile["login"]}",
      avatar: profile["avatar_url"],
      bio: profile["bio"],
      location: profile["location"],
      email: profile["email"],
      from_github: true
    }

    changeset =
      case profile |> Map.get("company") do
        nil ->
          %User{} |> Ecto.Changeset.change(attrs)

        _ ->
          %User{}
          |> Ecto.Changeset.change(attrs)
          |> Ecto.Changeset.put_embed(:work_backgrounds, [%{company: profile["company"]}])
      end

    Repo.insert(changeset)
  end

  defp create_profile(user, github_profile, :github) do
    # attrs = github_user |> Map.merge(%{github_id: github_user.id, user_id: 1}) |> Map.delete(:id)
    attrs =
      github_profile
      |> Map.merge(%{"github_id" => to_string(github_profile["id"]), "user_id" => user.id})
      # |> Map.merge(%{"github_id" => github_profile["id"], "user_id" => user.id})
      |> Map.delete("id")

    %GithubUser{}
    |> GithubUser.changeset(attrs)
    |> Repo.insert()
  end
end
