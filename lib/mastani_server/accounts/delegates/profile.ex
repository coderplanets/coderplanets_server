defmodule MastaniServer.Accounts.Delegate.Profile do
  @moduledoc """
  accounts profile
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, get_config: 2]
  import ShortMaps

  alias Helper.{Guardian, ORM, QueryBuilder}
  alias MastaniServer.Accounts.{GithubUser, User}
  alias MastaniServer.{CMS, Repo}

  alias Ecto.Multi

  @default_subscribed_communities get_config(:general, :default_subscribed_communities)

  def update_profile(%User{id: id}, attrs \\ %{}) do
    with {:ok, user} <- ORM.find(User, id) do
      case user.id === id do
        true -> user |> ORM.update(attrs)
        false -> {:error, "Error: not qualified"}
      end
    end
  end

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
        # IO.inspect label: "send back from db"
        token_info(user)

      {:error, _} ->
        # IO.inspect label: "register then send"
        register_github_user(github_user)
    end
  end

  @doc """
  get default subscribed communities for unlogin user
  """
  def default_subscribed_communities(%{page: _, size: _} = filter) do
    filter = Map.merge(filter, %{size: @default_subscribed_communities})
    CMS.Community |> ORM.find_all(filter)
  end

  @doc """
  get users subscribed communities
  """
  def subscribed_communities(%User{id: id}, %{page: page, size: size} = filter) do
    CMS.CommunitySubscriber
    |> where([c], c.user_id == ^id)
    |> join(:inner, [c], cc in assoc(c, :community))
    |> select([c, cc], cc)
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginater(~m(page size)a)
    |> done()
  end

  defp register_github_user(github_profile) do
    Multi.new()
    |> Multi.run(:create_user, fn _ ->
      create_user(github_profile, :github)
    end)
    |> Multi.run(:create_profile, fn %{create_user: user} ->
      create_profile(user, github_profile, :github)
    end)
    |> Repo.transaction()
    |> register_github_result()
  end

  defp register_github_result({:ok, %{create_user: user}}), do: token_info(user)

  defp register_github_result({:error, :create_user, _result, _steps}),
    do: {:error, "Accounts create_user internal error"}

  defp register_github_result({:error, :create_profile, _result, _steps}),
    do: {:error, "Accounts create_profile internal error"}

  defp token_info(%User{} = user) do
    with {:ok, token, _info} <- Guardian.jwt_encode(user) do
      {:ok, %{token: token, user: user}}
    end
  end

  defp create_user(user, :github) do
    user = %User{
      nickname: user["login"],
      avatar: user["avatar_url"],
      bio: user["bio"],
      location: user["location"],
      email: user["email"],
      company: user["company"],
      from_github: true
    }

    Repo.insert(user)
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
