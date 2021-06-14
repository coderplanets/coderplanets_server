defmodule GroupherServer.CMS.Helper.MatcherMacros do
  @moduledoc """
  generate match functions
  """
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS
  alias CMS.Model.{Comment, Embeds}

  @article_threads get_config(:article, :threads)

  @doc """
  match basic threads

  {:ok, info} <- match(:post)
  info:
  %{
    model: Post,
    thread: :post,
    foreign_key: post_id,
    preload: :post
    default_meta: ...
  }
  """
  defmacro thread_matches() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        def match(unquote(thread)) do
          thread_module = unquote(thread) |> to_string |> Recase.to_pascal()

          {:ok,
           %{
             model: Module.concat(CMS.Model, thread_module),
             thread: unquote(thread),
             foreign_key: unquote(:"#{thread}_id"),
             preload: unquote(thread),
             default_meta: Embeds.ArticleMeta.default_meta()
           }}
        end
      end
    end)
  end

  @doc """
  match basic thread query

  {:ok, info} <- match(:post, :query, id)
  info:
  %{dynamic([c], field(c, :post_id) == ^id)}
  """
  defmacro thread_query_matches() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        def match(unquote(thread), :query, id) do
          {:ok, dynamic([c], field(c, unquote(:"#{thread}_id")) == ^id)}
        end
      end
    end)
  end

  @doc """
  mapping basic comment -> thread

  {:ok, info} <- match(:comment_article, %Comment{post_id: id} = comment)
  info:
  %{
    id: id,
    model: CMS.Model.Post,
    foreign_key: :post_id,
  }
  """
  defmacro comment_article_matches() do
    @article_threads
    |> Enum.map(fn thread ->
      # def match(:comment_article, %Comment{post_id: id})
      quote do
        # see https://elixirforum.com/t/generate-map-pattern-matching-functions/21928/2
        def match(:comment_article, %Comment{unquote(:"#{thread}_id") => id})
            when not is_nil(id) do
          thread_module = unquote(thread) |> to_string |> Recase.to_pascal()

          {:ok,
           %{
             id: id,
             model: Module.concat(CMS.Model, thread_module),
             foreign_key: unquote(:"#{thread}_id")
           }}
        end
      end
    end)
  end
end
