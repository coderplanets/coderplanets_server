defmodule GroupherServerWeb.Schema.Helper.Mutations do
  @moduledoc """
  general mutations used for articles

  can not dedefine private macros, see:
  https://github.com/elixir-lang/elixir/issues/3887

  e.g:
  in schema/cms/mutation/post.ex

  add following:
    article_react_mutations(:post, [:upvote, :pin, :mark_delete, :delete, :emotion, :report, :sink, :lock_comment])

  it will expand as
    article_upvote_mutation(:radar)
    article_pin_mutation(:radar)
    article_mark_delete_mutation(:radar)
    article_delete_mutation(:radar)
    article_emotion_mutation(:radar)
    article_report_mutation(:radar)
    article_sink_mutation(:radar)
    article_lock_comment_mutation(:radar)

  same for the job/repo .. article thread
  """
  alias GroupherServerWeb.Middleware, as: M
  alias GroupherServerWeb.Resolvers, as: R

  @doc """
  add basic mutation reactions to article
  """
  defmacro article_react_mutations(thread, reactions) do
    reactions
    |> Enum.map(
      &quote do
        unquote(:"article_#{&1}_mutation")(unquote(thread))
      end
    )
  end

  @doc """
  upvote mutation for article

  include:
  -----
  upvote_[thread]
  unto_emotion_[thread]
  """
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

  @doc """
  pin mutation for article

  include:
  -----
  pin_[thread]
  unto_pin_[thread]
  """
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

  @doc """
  mark delete mutation for article

  include:
  -----
  mark_delete_[thread]
  unto_mark_delete_[thread]
  """
  defmacro article_mark_delete_mutation(thread) do
    quote do
      @desc unquote("mark delete a #{thread} type article, aka soft-delete")
      field unquote(:"mark_delete_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        middleware(M.Passport, claim: unquote("cms->#{to_string(thread)}.mark_delete"))

        resolve(&R.CMS.mark_delete_article/3)
      end

      @desc unquote("undo mark delete a #{thread} type article")
      field unquote(:"undo_mark_delete_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        middleware(M.Passport, claim: unquote("cms->#{to_string(thread)}.undo_mark_delete"))

        resolve(&R.CMS.undo_mark_delete_article/3)
      end
    end
  end

  @doc """
  delete mutation for article

  include:
  -----
  delete_[thread]
  mark_delete_[thread]
  """
  # TODO: if post belongs to multi communities, unset instead delete
  defmacro article_delete_mutation(thread) do
    quote do
      @desc unquote("delete a #{thread}, not delete")
      field unquote(:"delete_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))

        middleware(M.Authorize, :login)
        middleware(M.PassportLoader, source: unquote(thread))
        middleware(M.Passport, claim: unquote("owner;cms->c?->#{to_string(thread)}.delete"))

        resolve(&R.CMS.delete_article/3)
      end
    end
  end

  @doc """
  emotion mutation for article

  include:
  -----
  emotion_to_[thread]
  unto_emotion_to_[thread]
  """
  defmacro article_emotion_mutation(thread) do
    quote do
      @desc unquote("emotion to #{thread}")
      field unquote(:"emotion_to_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:emotion, non_null(:article_emotion))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        resolve(&R.CMS.emotion_to_article/3)
      end

      @desc unquote("undo emotion to #{thread}")
      field unquote(:"undo_emotion_to_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:emotion, non_null(:article_emotion))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        resolve(&R.CMS.undo_emotion_to_article/3)
      end
    end
  end

  @doc """
  report mutation for article

  include:
  -----
  report_[thread]
  undo_report_[thread]
  """
  defmacro article_report_mutation(thread) do
    quote do
      @desc unquote("report a #{thread}")
      field unquote(:"report_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:reason, non_null(:string))
        arg(:attr, :string, default_value: "")
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        resolve(&R.CMS.report_article/3)
      end

      @desc unquote("undo report a #{thread}")
      field unquote(:"undo_report_#{thread}"), unquote(thread) do
        arg(:id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        resolve(&R.CMS.undo_report_article/3)
      end
    end
  end

  @doc """
  sink mutation for article

  include:
  -----
  sink_[thread]
  undo_sink_[thread]
  """
  defmacro article_sink_mutation(thread) do
    quote do
      @desc unquote("sink a #{thread}")
      field unquote(:"sink_#{thread}"), :article do
        arg(:id, non_null(:id))
        arg(:community_id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        middleware(M.PassportLoader, source: :community)
        middleware(M.Passport, claim: unquote("cms->c?->#{to_string(thread)}.sink"))
        resolve(&R.CMS.sink_article/3)
      end

      @desc unquote("undo sink to #{thread}")
      field unquote(:"undo_sink_#{thread}"), :article do
        arg(:id, non_null(:id))
        arg(:community_id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        middleware(M.PassportLoader, source: :community)
        middleware(M.Passport, claim: unquote("cms->c?->#{to_string(thread)}.undo_sink"))
        resolve(&R.CMS.undo_sink_article/3)
      end
    end
  end

  @doc """
  lock comment of a article

  include:
  -----
  lock_[thread]_comment
  undo_lock_[thread]_comment
  """
  defmacro article_lock_comment_mutation(thread) do
    quote do
      @desc unquote("lock comment of a #{thread}")
      field unquote(:"lock_#{thread}_comment"), :article do
        arg(:id, non_null(:id))
        arg(:community_id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        middleware(M.PassportLoader, source: :community)
        middleware(M.Passport, claim: unquote("cms->c?->#{to_string(thread)}.lock_comment"))
        resolve(&R.CMS.lock_article_comments/3)
      end

      @desc unquote("undo lock to a #{thread}")
      field unquote(:"undo_lock_#{thread}_comment"), :article do
        arg(:id, non_null(:id))
        arg(:community_id, non_null(:id))
        arg(:thread, unquote(:"#{thread}_thread"), default_value: unquote(thread))

        middleware(M.Authorize, :login)
        middleware(M.PassportLoader, source: :community)
        middleware(M.Passport, claim: unquote("cms->c?->#{to_string(thread)}.undo_lock_comment"))
        resolve(&R.CMS.undo_lock_article_comments/3)
      end
    end
  end
end
