defmodule GroupherServerWeb.Controller.OG do
  @moduledoc """
  handle open-graph info
  """
  use GroupherServerWeb, :controller
  # alias Todos.Todo
  # plug(:action)

  def index(conn, %{"url" => url}) do
    fetch_opengraph_info(conn, url)
  end

  # return editor-js flavor fmt
  # see https://github.com/editor-js/link
  defp fetch_opengraph_info(conn, url) do
    case OpenGraph.fetch(url) do
      {:ok, info} ->
        ok_response(conn, url, info)

      {:error, reason} ->
        error_response(conn, url, reason)
    end
  end

  defp ok_response(conn, url, %OpenGraph{title: nil, description: nil}) do
    error_response(conn, url)
  end

  defp ok_response(conn, _url, %OpenGraph{title: nil, description: description} = info)
       when not is_nil(description) do
    json(conn, %{
      success: 1,
      meta: %{
        title: info.description |> String.slice(0, 8),
        description: info.description,
        image: %{
          url: nil
        }
      }
    })
  end

  defp ok_response(conn, _url, info) do
    json(conn, %{
      success: 1,
      meta: %{
        title: info.title,
        description: info.description,
        image: %{
          url: info.image
        }
      }
    })
  end

  defp error_response(conn, url) do
    json(conn, %{
      success: 1,
      meta: %{
        title: url,
        description: url,
        image: %{
          url: nil
        }
      }
    })
  end

  defp error_response(conn, _url, :nxdomain) do
    json(conn, %{
      success: 0,
      meta: %{
        title: "domain-not-exsit",
        description: "--",
        image: %{
          url: nil
        }
      }
    })
  end

  defp error_response(conn, _url, :timeout) do
    json(conn, %{
      success: 0,
      meta: %{
        title: "timeout",
        description: "--",
        image: %{
          url: nil
        }
      }
    })
  end

  defp error_response(conn, url, "Not found :(") do
    json(conn, %{
      success: 1,
      meta: %{
        title: url,
        description: "--",
        image: %{
          url: nil
        }
      }
    })
  end

  defp error_response(conn, _url, _reason) do
    json(conn, %{
      success: 0,
      meta: %{
        title: "unknown-error",
        description: nil,
        image: %{
          url: nil
        }
      }
    })
  end
end
