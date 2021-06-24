defmodule GroupherServer.Test.ConnSimulator do
  @moduledoc """
  mock user_conn, owner_conn, guest_conn
  """
  import GroupherServer.Support.Factory
  import Phoenix.ConnTest, only: [build_conn: 0]
  import Plug.Conn, only: [put_req_header: 3]

  import GroupherServer.CMS.Delegate.Helper, only: [author_of: 1]

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias Helper.{Guardian, ORM}

  @spec simu_conn(:guest | :invalid_token | :user) :: Plug.Conn.t()
  def simu_conn(:guest) do
    build_conn()
  end

  def simu_conn(:user) do
    user_attr = mock_attrs(:user)
    {:ok, user} = db_insert(:user, user_attr)
    token = gen_jwt_token(id: user.id)

    build_conn() |> put_req_header("authorization", token)
  end

  def simu_conn(:invalid_token) do
    token = "invalid_token"

    build_conn() |> put_req_header("authorization", token)
  end

  def simu_conn(:owner, content) do
    with {:ok, author} <- author_of(content) do
      token = gen_jwt_token(id: author.id)

      build_conn() |> put_req_header("authorization", token)
    end
  end

  def simu_conn(:user, %User{} = user) do
    token = gen_jwt_token(id: user.id)

    build_conn() |> put_req_header("authorization", token)
  end

  def simu_conn(:user, cms: passport_rules) do
    user_attr = mock_attrs(:user)
    {:ok, user} = db_insert(:user, user_attr)

    token = gen_jwt_token(id: user.id)

    {:ok, _passport} = CMS.stamp_passport(passport_rules, %User{id: user.id})

    build_conn() |> put_req_header("authorization", token)
  end

  def simu_conn(:user, %User{} = user, cms: passport_rules) do
    token = gen_jwt_token(id: user.id)

    {:ok, _passport} = CMS.stamp_passport(passport_rules, %User{id: user.id})

    build_conn() |> put_req_header("authorization", token)
  end

  defp gen_jwt_token(clauses) do
    with {:ok, user} <- ORM.find_by(User, clauses) do
      {:ok, token, _info} = Guardian.jwt_encode(user)

      "Bearer #{token}"
    end
  end
end
