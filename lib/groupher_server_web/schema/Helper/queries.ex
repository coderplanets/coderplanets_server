defmodule GroupherServerWeb.Schema.Helper.Queries do
  @moduledoc """
  common fields
  """
  import Helper.Utils, only: [get_config: 2, plural: 1]

  alias GroupherServerWeb.Middleware, as: M
  alias GroupherServerWeb.Resolvers, as: R

  @article_threads get_config(:article, :threads)

  # user published articles
  defmacro published_article_queries() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        @desc unquote("paged published #{plural(thread)}")
        field unquote(:"paged_published_#{plural(thread)}"),
              unquote(:"paged_#{plural(thread)}") do
          arg(:login, non_null(:string))
          arg(:filter, non_null(:paged_filter))
          arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

          middleware(M.PageSizeProof)
          resolve(&R.Accounts.paged_published_articles/3)
        end
      end
    end)
  end

  defmacro article_search_queries() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        @desc unquote("get #{thread} by id")
        field unquote(:"search_#{plural(thread)}"), unquote(:"paged_#{plural(thread)}") do
          arg(:title, non_null(:string))
          arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

          resolve(&R.CMS.search_articles/3)
        end
      end
    end)
  end

  @doc """
  query generator for threads, like:

  post, page_posts ...
  """
  defmacro article_queries() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        @desc unquote("get #{thread} by id")
        field unquote(thread), non_null(unquote(thread)) do
          arg(:id, non_null(:id))
          arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

          resolve(&R.CMS.read_article/3)
        end

        @desc unquote("get paged #{plural(thread)}")
        field unquote(:"paged_#{plural(thread)}"), unquote(:"paged_#{plural(thread)}") do
          arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))
          arg(:filter, non_null(unquote(:"paged_#{plural(thread)}_filter")))

          middleware(M.PageSizeProof, default_sort: :desc_active)
          resolve(&R.CMS.paged_articles/3)
        end
      end
    end)
  end

  defmacro article_reacted_users_query(action, resolver) do
    quote do
      @desc unquote("get paged #{action}ed users of an article")
      field unquote(:"#{action}ed_users"), :paged_users do
        arg(:id, non_null(:id))
        arg(:thread, :thread, default_value: :post)
        arg(:filter, non_null(:paged_filter))

        middleware(M.PageSizeProof)
        resolve(unquote(resolver))
      end
    end
  end
end
