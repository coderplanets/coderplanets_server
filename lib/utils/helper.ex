defmodule MastaniServer.Utils.Helper do
  alias MastaniServer.Repo
  import Ecto.Query, warn: false

  @doc """
  return General {:ok, ..} or {:error, ..} return value
  """

  def find(reactor, id, preload: preload) do
    reactor
    |> where([c], c.id == ^id)
    |> preload(^preload)
    |> Repo.one()
    |> one_resp()
  end

  def find(reactor, id) do
    reactor
    |> where([c], c.id == ^id)
    |> Repo.one()
    |> one_resp()
  end

  def one_resp(message) do
    case message do
      nil ->
        {:error, "record not found."}

      result ->
        {:ok, result}
    end
  end

  def access_deny(type) do
    case type do
      :login -> {:error, "Access denied: need login to do this"}
      :owner_required -> {:error, "Access denied: need owner to do this"}
      :root -> {:error, "need root to do this"}
    end
  end

  def orm_resp(message) do
    case message do
      {:ok, result} ->
        {:ok, result}

      nil ->
        {:error, "record not found"}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, format_error(changeset)}

      {:error, %{limit: limit}} ->
        {
          :error,
          "first / limit only support arg < #{limit}, if you want more, use pagedXXX version. example: pagedComments(..)"
        }

      {:error, reason} ->
        {:error, reason}
    end
  end

  # def orm_resp(message, extra_error: ) do

  def orm_resp(message, err_code: code) do
    case message do
      {:ok, result} ->
        {:ok, result}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, format_error(changeset, code)}

      {:error, %{limit: limit}} ->
        {
          :error,
          "first / limit only support arg < #{limit}, if you want more, use pagedXXX version. example: pagedComments(..)"
        }

      {:error, reason} ->
        {:error, reason}
    end
  end

  # http://www.thisisnotajoke.com/blog/2015/09/serializing-ecto-changeset-errors-to-jsonapi-in-elixir.html
  # valid error format
  #   {:error, ["Simple message", [message: "A keyword list error", code: 1], %{message: "A map error"}]}
  #   {:error, %{message: "A database error occurred", details: "format_db_error(some_value)", code: 234}}
  #   {:error, ["Something bad", "Even worse"]}
  #   {:error, message: "Unknown user", code: 21}
  defp format_error(changeset, code \\ 710) do
    Enum.map(changeset.errors, fn {field, detail} ->
      %{
        code: code,
        message: "#{field} #{render_detail(detail)}"
      }
    end)
  end

  defp render_detail({message, values}) do
    Enum.reduce(values, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end)
  end

  defp render_detail(message) do
    message
  end

  def filter_pack(query, filter) do
    Enum.reduce(filter, query, fn
      {:first, first}, query ->
        cond do
          first > 30 -> query |> limit(30)
          true -> query |> limit(^first)
        end

      {:sort, :most_views}, query ->
        query |> order_by(desc: :views)

      {:sort, :least_views}, query ->
        query |> order_by(asc: :views)

      {:sort, :most_stars}, query ->
        query
        |> join(:left, [p], s in assoc(p, :stars))
        |> group_by([p], p.id)
        |> select([p], p)
        |> order_by([p, s], desc: fragment("count(?)", s.id))

      {:sort, :least_stars}, query ->
        query
        |> join(:left, [p], s in assoc(p, :stars))
        |> group_by([p], p.id)
        |> select([p], p)
        |> order_by([p, s], asc: fragment("count(?)", s.id))

      {:when, :today}, query ->
        # date = DateTime.utc_now() |> Timex.to_datetime()
        # use timezone info is server is not in the some timezone
        # Timex.now("America/Chicago")
        date = Timex.now

        query
        |> where([p], p.inserted_at >= ^Timex.beginning_of_day(date))
        |> where([p], p.inserted_at <= ^Timex.end_of_day(date))

      {:when, :this_week}, query ->
        date = Timex.now

        query
        |> where([p], p.inserted_at >= ^Timex.beginning_of_week(date))
        |> where([p], p.inserted_at <= ^Timex.end_of_week(date))

      {:when, :this_month}, query ->
        date = Timex.now

        query
        |> where([p], p.inserted_at >= ^Timex.beginning_of_month(date))
        |> where([p], p.inserted_at <= ^Timex.end_of_month(date))

      {:when, :this_year}, query ->
        date = Timex.now

        query
        |> where([p], p.inserted_at >= ^Timex.beginning_of_year(date))
        |> where([p], p.inserted_at <= ^Timex.end_of_year(date))

      # TODO :all
      {_, :all}, query ->
        query

      {:tag, tag_name}, query ->
        from(
          q in query,
          join: t in assoc(q, :tags),
          where: t.title == ^tag_name
        )

      {:community, community_name}, query ->
        from(
          q in query,
          join: t in assoc(q, :communities),
          where: t.title == ^community_name
        )

      {_, _}, query ->
        query
    end)
  end
end
