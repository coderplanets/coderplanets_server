defmodule Helper.RSS do
  @moduledoc """
  RSS get and parser
  """
  use Tesla, only: [:get]
  import Helper.Utils, only: [done: 1]

  @timeout_limit 4000

  plug(Tesla.Middleware.Retry, delay: 200, max_retries: 2)
  plug(Tesla.Middleware.Timeout, timeout: @timeout_limit)
  plug(Tesla.Middleware.JSON)

  def query(rss) do
    with {:ok, %{body: body}} <- get(rss),
         {:ok, blog_rss} <- rss_parser(body) do
      blog_rss |> Map.merge(%{rss: rss}) |> done
    else
      _ ->
        {:error, :invalid_rss_address}
    end
  end

  defp rss_parser(body) do
    with {:ok, feed} <- Fiet.Atom.parse(body) do
      format(:atom, feed)
    else
      {:error, %Fiet.Atom.ParsingError{reason: {:not_atom, "rss"}}} ->
        rss_parser(body, :rss2)

      {:error, %HTTPoison.Error{id: nil, reason: :timeout}} ->
        {:error, "fetch rss timeout"}

      {:error, error} ->
        IO.inspect(error, label: "rss parser error")
        {:error, "unknow token"}
    end
  end

  defp rss_parser(body, :rss2) do
    with {:ok, feed} <- Fiet.RSS2.parse(body) do
      # IO.inspect(feed, label: "rss2 feed")
      format(:rss2, feed)
    end
  end

  defp format(:atom, %Fiet.Atom.Feed{entries: entries} = feed) do
    items =
      Enum.reduce(entries, [], fn item, acc ->
        acc ++ [format(:item, item)]
      end)

    {:ok,
     %{
       title: parse(:text, feed.title),
       subtitle: parse(:text, feed.subtitle),
       link: parse(:link, feed),
       updated: feed.updated,
       history_feed: items
     }}
  end

  defp format(:rss2, %Fiet.RSS2.Channel{items: items} = feed) do
    items =
      Enum.reduce(items, [], fn item, acc ->
        acc ++ [format(:item, item)]
      end)

    {:ok,
     %{
       title: feed.title,
       subtitle: feed.description,
       link: feed.link,
       updated: feed.last_build_date,
       history_feed: items
     }}
  end

  defp format(:item, %Fiet.Atom.Entry{} = item) do
    %{
      title: parse(:text, item.title),
      digest: parse(:digest, item),
      link_addr: parse(:link, item),
      #
      published: parse(:published, item),
      updated: item.updated
    }
  end

  defp format(:item, %Fiet.RSS2.Item{} = item) do
    %{
      title: item.title,
      digest: item.description,
      link_addr: item.link,
      #
      published: item.pub_date,
      updated: item.pub_date
    }
  end

  defp parse(:digest, %Fiet.Atom.Entry{summary: nil}), do: "use content TODO"
  defp parse(:digest, %Fiet.Atom.Entry{summary: summary}), do: parse(:text, summary)
  defp parse(:digest, _), do: "use content TODO"

  defp parse(:text, {:text, text}), do: text
  defp parse(:text, _), do: ""

  defp parse(:link, %Fiet.Atom.Entry{links: links}), do: do_parse_link(links)
  defp parse(:link, %Fiet.Atom.Feed{links: links}), do: do_parse_link(links)

  defp parse(:published, %Fiet.Atom.Entry{published: nil, updated: updated}) do
    updated
  end

  defp parse(:published, %Fiet.Atom.Entry{published: published}) do
    published
  end

  defp do_parse_link([]), do: ""

  defp do_parse_link(links) do
    case Enum.find(links, &(&1.type === "text/html")) do
      nil -> links |> List.first() |> Map.get(:href)
      link -> link.href
    end
  end
end
