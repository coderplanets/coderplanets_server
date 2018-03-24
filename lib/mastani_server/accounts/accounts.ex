defmodule MastaniServer.Accounts do
  import Ecto.Query, warn: false
  alias MastaniServer.Repo
  alias Ecto.Multi

  alias MastaniServer.Accounts.{User, GithubUser}
  alias Helper.ORM
  alias Helper.MastaniServer.Guardian

  def data(), do: Dataloader.Ecto.new(Repo, query: &query/2)

  def query(queryable, _args) do
    IO.inspect(queryable, label: 'account default query')
    queryable
  end

  @doc """
  github_login steps:
  ------------------
  step 0: get access_token is enough, even profile is not need?
  step 1: check is access_token valid or not, think use a Middleware
  step 2.1: if access_token's github_id exsit, then login
  step 2.2: if access_token's github_id not exsit, then signup
  step 3: return mastani token
  """
  def github_login(github_user) do
    case ORM.find_by(GithubUser, github_id: to_string(github_user["id"])) do
      {:ok, g_user} ->
        # 直接返回 token
        # IO.inspect("found user, return token")
        ORM.find_by(User, id: g_user.user_id)

      {:error, reason} ->
        # 注册 user, github_user 并返回 token
        # IO.inspect(reason, label: "not found")
        # IO.inspect("not found user, register and return token")
        register_github_user(github_user)
    end
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

  defp register_github_result({:ok, %{create_user: user}}) do
    with {:ok, token, _info} <- Guardian.jwt_encode(user) do
      {:ok, %{token: token}}
    end
  end

  defp register_github_result({:error, :create_user, _result, _steps}),
    do: {:error, "Accounts create_user internal error"}

  defp register_github_result({:error, :create_profile, _result, _steps}),
    do: {:error, "Accounts create_profile internal error"}

  defp create_user(user, :github) do
    # attr = %{nickname: user["login"], avatar: user["avatar_url"], bio: user["bio"]}
    # %User{}
    # |> User.changeset(attr)
    # |> Repo.insert()

    user = %User{
      nickname: user["login"],
      avatar: user["avatar_url"],
      bio: user["bio"],
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

  def list_users do
    Repo.all(User)
  end

  def create_user2(attrs \\ %{}) do
    # changeset = User.changeset(%User{}, attrs)
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def login(user_id) do
    case ORM.find(Accounts.User, user_id) do
      {:ok, user} ->
        IO.inspect(user, label: "sign token: ")
        Guardian.jwt_encode(user, %{hello: "world"})

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end
end
