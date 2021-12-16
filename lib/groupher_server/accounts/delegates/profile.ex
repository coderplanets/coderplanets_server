defmodule GroupherServer.Accounts.Delegate.Profile do
  @moduledoc """
  accounts profile
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, get_config: 2, ensure: 2]
  import ShortMaps

  alias GroupherServer.{Accounts, CMS, Email, Repo, Statistics}

  alias Accounts.Model.{Achievement, GithubUser, User, Social, Embeds}
  alias CMS.Model.{Community, CommunitySubscriber}

  alias GroupherServer.Accounts.Delegate.Fans

  alias Helper.{Guardian, ORM, QueryBuilder, IP2City}
  alias Ecto.Multi

  @default_user_meta Embeds.UserMeta.default_meta()
  @default_subscribed_communities get_config(:general, :default_subscribed_communities)

  def read_user(login) when is_binary(login) do
    with {:ok, user} <- ORM.read_by(User, %{login: login}, inc: :views),
         {:ok, user} <- assign_meta_ifneed(user) do
      case user.contributes do
        nil -> assign_default_contributes(user)
        _ -> {:ok, user}
      end
    end
  end

  def read_user(login, %User{meta: nil}), do: read_user(login)

  def read_user(login, %User{} = cur_user) do
    with {:ok, user} <- read_user(login) do
      # Ta 关注了你
      viewer_been_followed = user.id in cur_user.meta.follower_user_ids
      # 正在关注
      viewer_has_followed = user.id in cur_user.meta.following_user_ids

      user =
        Map.merge(user, %{
          viewer_been_followed: viewer_been_followed,
          viewer_has_followed: viewer_has_followed
        })

      {:ok, user}
    end
  end

  defp assign_meta_ifneed(%User{meta: nil} = user) do
    {:ok, Map.merge(user, %{meta: @default_user_meta})}
  end

  defp assign_meta_ifneed(user) do
    {:ok, user}
  end

  def paged_users(filter, %User{} = user) do
    ORM.find_all(User, filter) |> Fans.mark_viewer_follow_status(user) |> done
  end

  def paged_users(filter) do
    ORM.find_all(User, filter)
  end

  @doc """
  update user's profile
  """
  def update_profile(%User{} = user, attrs \\ %{}) do
    changeset = user |> Ecto.Changeset.change(attrs)

    changeset
    |> update_social_ifneed(user, attrs)
    |> embed_background_ifneed(changeset)
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  update user's subscribed communities count
  """
  def update_subscribe_state(user_id) do
    with {:ok, user} <- ORM.find(User, user_id) do
      query =
        from(s in CommunitySubscriber,
          where: s.user_id == ^user.id,
          join: c in assoc(s, :community),
          select: c.id
        )

      subscribed_communities_ids = query |> Repo.all()
      subscribed_communities_count = subscribed_communities_ids |> length

      user_meta = ensure(user.meta, @default_user_meta)
      meta = %{user_meta | subscribed_communities_ids: subscribed_communities_ids}

      user
      |> ORM.update_meta(meta,
        changes: %{subscribed_communities_count: subscribed_communities_count}
      )
    end
  end

  @doc """
  update geo info for user, include geo_city & remote ip
  """
  def update_geo(%User{geo_city: geo_city} = user, remote_ip) when is_nil(geo_city) do
    case IP2City.locate_city(remote_ip) do
      {:ok, city} ->
        update_profile(user, %{geo_city: city, remote_ip: remote_ip})

      {:error, _} ->
        update_profile(user, %{remote_ip: remote_ip})
        {:ok, :pass}
    end
  end

  def update_geo(%User{} = user, remote_ip), do: update_profile(user, %{remote_ip: remote_ip})
  def update_geo(_user, _remote_ip), do: {:ok, :pass}

  @doc """
  github_signin steps:
  ------------------
  step 0: get access_token is enough, even profile is not need?
  step 1: check is access_token valid or not, think use a Middleware
  step 2.1: if access_token's github_id exsit, then login
  step 2.2: if access_token's github_id not exsit, then signup
  step 3: return groupher token
  """
  def github_signin(github_user) do
    case ORM.find_by(GithubUser, github_id: to_string(github_user["id"])) do
      {:ok, g_user} ->
        {:ok, user} = ORM.find(User, g_user.user_id)
        gen_token(user)

      {:error, _} ->
        register_github_user(github_user)
    end
  end

  @doc """
  get default subscribed communities for unlogin user
  """
  def default_subscribed_communities(%{page: _, size: _} = filter) do
    filter = Map.merge(filter, %{size: @default_subscribed_communities, category: "pl"})

    with {:ok, home_community} <- ORM.find_by(Community, raw: "home"),
         {:ok, paged_communities} <- ORM.find_all(Community, filter) do
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
    CommunitySubscriber
    |> where([c], c.user_id == ^id)
    |> join(:inner, [c], cc in assoc(c, :community))
    |> select([c, cc], cc)
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginator(~m(page size)a)
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
    |> Multi.run(:update_profile_social, fn _, %{create_user: user} ->
      update_profile_social(user, github_profile, :github)
    end)
    |> Multi.run(:init_achievement, fn _, %{create_user: user} ->
      Achievement |> ORM.upsert_by([user_id: user.id], %{user_id: user.id})
    end)
    |> Repo.transaction()
    |> register_github_result
  end

  defp register_github_result({:ok, %{create_user: create_user}}) do
    {:ok, user} = ORM.find(User, create_user.id, preload: :github_profile)

    with {:ok, result} <- gen_token(user) do
      Email.welcome(user)
      Email.notify_admin(user, :new_register)

      {:ok, result}
    end
  end

  defp register_github_result({:error, :create_user, %Ecto.Changeset{} = result, _steps}),
    do: {:error, result}

  defp register_github_result({:error, :create_user, _result, _steps}),
    do: {:error, "Accounts create_user internal error"}

  defp register_github_result({:error, :create_profile, _result, _steps}),
    do: {:error, "Accounts create_profile internal error"}

  defp register_github_result({:error, :update_profile_social, _result, _steps}),
    do: {:error, "Accounts update_profile_social error"}

  defp gen_token(%User{} = user) do
    with {:ok, token, _info} <- Guardian.jwt_encode(user) do
      {:ok, %{token: token, user: user}}
    end
  end

  defp create_user(profile, :github) do
    attrs = %{
      login: String.downcase(profile["login"]),
      nickname: profile["login"],
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

  def update_profile_social(user, profile, :github) do
    update_social_ifneed(user, %{
      social: %{
        github: "https://github.com/#{profile["login"]}"
      }
    })
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

  defp update_social_ifneed(%User{} = user, %{social: attrs}) do
    attrs = Map.merge(%{user_id: user.id}, attrs)
    Social |> ORM.upsert_by([user_id: user.id], attrs)
  end

  defp update_social_ifneed(changeset, %User{} = user, %{social: attrs}) do
    case ORM.find_by(Social, user_id: user.id) do
      {:ok, _} ->
        ORM.update_by(Social, [user_id: user.id], attrs)
        Ecto.Changeset.put_change(changeset, :social, nil)

      {:error, _} ->
        ORM.create(Social, attrs)
        changeset
    end
  end

  defp update_social_ifneed(changeset, _user, _attrs), do: changeset

  defp embed_background_ifneed(%Ecto.Changeset{} = changeset, attrs) do
    cond do
      Map.has_key?(attrs, :education_backgrounds) ->
        changeset
        |> Ecto.Changeset.put_embed(:education_backgrounds, attrs.education_backgrounds)

      Map.has_key?(attrs, :work_backgrounds) ->
        changeset
        |> Ecto.Changeset.put_embed(:work_backgrounds, attrs.work_backgrounds)

      true ->
        changeset
    end
  end

  # assign default contributes
  defp assign_default_contributes(%User{} = user) do
    {:ok, contributes} = Statistics.list_contributes_digest(%User{id: user.id})
    ORM.update_embed(user, :contributes, contributes)
  end
end
