# a plug for router ...

defmodule MastaniServerWeb.Context do
  @behaviour Plug

  import Plug.Conn
  # import Ecto.Query, only: [first: 1]

  alias MastaniServer.{Accounts, CMS}
  alias Helper.{Guardian, ORM}

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
    # IO.inspect conn.remote_ip, label: "conn"
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, cur_user} <- authorize(token) do
      IO.inspect conn.remote_ip, label: "build content conn.remote_ip"
      %{cur_user: cur_user, remote_ip: conn.remote_ip}
    else
      _ -> %{}
    end
  end

  defp authorize(token) do
    with {:ok, claims, _info} <- Guardian.jwt_decode(token) do
      case ORM.find(Accounts.User, claims.id) do
        {:ok, user} ->
          check_passport(user)

        {:error, _} ->
          {:error,
           "user is not exsit, try revoke token, or if you in dev env run the seeds first."}
      end
    end
  end

  # TODO gather role info from CMS or other context
  defp check_passport(%Accounts.User{} = user) do
    with {:ok, cms_passport} <- CMS.get_passport(%Accounts.User{id: user.id}) do
      {:ok, Map.put(user, :cur_passport, %{"cms" => cms_passport})}
    else
      {:error, _} -> {:ok, user}
    end
  end
end
