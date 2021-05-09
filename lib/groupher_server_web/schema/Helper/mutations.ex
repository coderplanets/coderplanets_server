defmodule GroupherServerWeb.Schema.Helper.Mutations do
  @moduledoc """
  common fields
  """
  alias GroupherServerWeb.Middleware, as: M
  alias GroupherServerWeb.Resolvers, as: R

  defmacro article_upvote_mutation(thread) do
    quote do
      @desc unquote("upvote to #{thread}")
      field unquote(:"upvote_#{thread}"), :article do
        arg(:id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        resolve(&R.CMS.upvote_article/3)
      end

      @desc unquote("undo upvote to #{thread}")
      field unquote(:"undo_upvote_#{thread}"), :article do
        arg(:id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        resolve(&R.CMS.undo_upvote_article/3)
      end
    end
  end
end
