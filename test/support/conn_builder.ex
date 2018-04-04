defmodule MastaniServer.Test.ConnBuilder do
  @moduledoc """
  mock user_conn, owner_conn, guest_conn
  """

  alias MastaniServer.{Accounts, CMS}
  alias Helper.MastaniServer.Guardian
  alias Helper.ORM

  import Phoenix.ConnTest, only: [build_conn: 0]
  import Plug.Conn, only: [put_req_header: 3]

  import MastaniServer.Factory

  def mock_conn(:guest) do
    build_conn()
  end

  def mock_conn(:owner, content) do
    token = gen_jwt_token(id: content.author.user.id)

    build_conn() |> put_req_header("authorization", token)
  end

  def mock_conn(:user, %Accounts.User{} = user) do
    token = gen_jwt_token(id: user.id)

    build_conn() |> put_req_header("authorization", token)
  end

  def mock_conn(:user) do
    user_attr = mock_attrs(:user)
    {:ok, user} = db_insert(:user, user_attr)
    token = gen_jwt_token(id: user.id)

    build_conn() |> put_req_header("authorization", token)
  end

  def mock_conn(:user, passport_rules) do
    user_attr = mock_attrs(:user)
    {:ok, user} = db_insert(:user, user_attr)

    token = gen_jwt_token(id: user.id)

    {:ok, _passport} = CMS.stamp_passport(%Accounts.User{id: user.id}, passport_rules)

    conn =
      build_conn()
      |> put_req_header("authorization", token)

    # |> put_req_header.("content-type", "application/json")
  end

  defp gen_jwt_token(clauses) do
    with {:ok, user} <- ORM.find_by(Accounts.User, clauses) do
      {:ok, token, _info} = Guardian.jwt_encode(user)

      "Bearer #{token}"
    end
  end
end
