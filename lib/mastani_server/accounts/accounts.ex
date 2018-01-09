defmodule MastaniServer.Accounts do
  import Ecto.Query, warn: false
  alias MastaniServer.Repo

  alias MastaniServer.Accounts.User
  alias MastaniServer.Utils.Guardian

  def list_users do
    Repo.all(User)
  end

  def get_user(id), do: Repo.get(User, id)

  def find_user(id) do
    case get_user(id) do
      nil ->
        {:error, "user id #{id} not found."}

      user ->
        {:ok, user}
    end
  end

  def create_user(attrs \\ %{}) do
    # changeset = User.changeset(%User{}, attrs)
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def login(user_id) do
    case find_user(user_id) do
      {:ok, user} ->
        IO.inspect(user, label: "sign token: ")
        Guardian.encode_and_sign(user, %{hello: "world"})

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
