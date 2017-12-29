defmodule MastaniServer.Utils.Hepler do
  alias MastaniServer.Repo

  def repo_insert(changeset) do
    case Repo.insert(changeset) do
      {:ok, whatever} ->
        {:ok, whatever}

      {:error, changeset} ->
        # IO.inspect(changeset, label: "create user")
        # IO.inspect(errors, label: "after")
        {:error, format_error(changeset)}
    end
  end

  # http://www.thisisnotajoke.com/blog/2015/09/serializing-ecto-changeset-errors-to-jsonapi-in-elixir.html
  # valid error format
  #   {:error, ["Simple message", [message: "A keyword list error", code: 1], %{message: "A map error"}]}
  #   {:error, %{message: "A database error occurred", details: "format_db_error(some_value)", code: 234}}
  #   {:error, ["Something bad", "Even worse"]}
  #   {:error, message: "Unknown user", code: 21}
  defp format_error(changeset) do
    Enum.map(changeset.errors, fn {field, detail} ->
      %{
        code: 22,
        message: "#{field}",
        detail: render_detail(detail)
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

  @doc """
  return General {:ok, ..} or {:error, ..} return value
  """

  def deal_withit(message) do
    case message do
      {:ok, whatever} ->
        {:ok, whatever}

      {:error, reason} ->
        {:error, reason}
    end
  end

end
