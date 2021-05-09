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

  defmacro article_pin_mutation(thread) do
    quote do
      @desc unquote("pin to #{thread}")
      field unquote(:"pin_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:community_id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        middleware(M.PassportLoader, source: :community)
        middleware(M.Passport, claim: unquote("cms->c?->#{to_string(thread)}.pin"))
        resolve(&R.CMS.pin_article/3)
      end

      @desc unquote("undo pin to #{thread}")
      field unquote(:"undo_pin_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:community_id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        middleware(M.PassportLoader, source: :community)
        middleware(M.Passport, claim: unquote("cms->c?->#{to_string(thread)}.undo_pin"))
        resolve(&R.CMS.undo_pin_article/3)
      end
    end
  end
end
