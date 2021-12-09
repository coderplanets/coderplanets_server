# a plug for router ...

defmodule GroupherServerWeb.Context do
  @moduledoc """
  entry for all api
  """
  @behaviour Plug

  import Plug.Conn
  # import Ecto.Query, only: [first: 1]

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias Helper.{Guardian, ORM, RemoteIP}

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    # put_private(conn, :absinthe, %{context: context})
    # TODO: use https://github.com/absinthe-graphql/absinthe/pull/497/files
    Absinthe.Plug.put_options(conn, context: context)
  end

  @doc """
  Return the current user context based on the authorization header.

  Important: Note that at the current time this is just a stub, always
  returning the first user (marked as an admin), provided any
  authorization header is sent.
  """
  def build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, cur_user} <- authorize(token) do
      # IO.inspect(
      #   RemoteIP.parse(get_req_header(conn, "x-forwarded-for")),
      #   label: "#># x-forwarded-for"
      # )

      case RemoteIP.parse(get_req_header(conn, "x-forwarded-for")) do
        {:ok, remote_ip} ->
          %{cur_user: cur_user, remote_ip: remote_ip}

        {:error, _} ->
          %{cur_user: cur_user}
      end
    else
      _ -> %{}
    end
  end

  defp authorize(token) do
    with {:ok, claims, _info} <- Guardian.jwt_decode(token) do
      case ORM.find(User, claims.id, preload: :customization) do
        {:ok, user} ->
          check_passport(user)

        {:error, _} ->
          {:error,
           "user is not exsit, try revoke token, or if you in dev env run the seeds first."}
      end
    end
  end

  # TODO gather role info from CMS or other context
  defp check_passport(%User{} = user) do
    with {:ok, cms_passport} <- CMS.get_passport(%User{id: user.id}) do
      {:ok, Map.put(user, :cur_passport, %{"cms" => cms_passport})}
    else
      {:error, _} -> {:ok, user}
    end
  end
end
