defmodule MastaniServer.Utils.Hepler do
  @doc """
  return General {:ok, ..} or {:error, ..} return value
  """

  # defguardp is_empty(s) when byte_sise(error) == 0

  def access_deny(type) do
    case type do
      :login -> {:error, "Access denied: need login"}
      :root -> {:error, "need root to do this"}
    end
  end

  def orm_resp(message) do
    case message do
      {:ok, whatever} ->
        {:ok, whatever}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, format_error(changeset)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def orm_resp(message, err_code: code) do
    case message do
      {:ok, whatever} ->
        {:ok, whatever}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, format_error(changeset, code)}

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
end
