defmodule GroupherServer.CMS.Helper.Matcher do
  @moduledoc """
  this module defined the matches and handy guard ...
  """

  import Ecto.Query, warn: false
  import GroupherServer.CMS.Helper.MatcherMacros

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.Model.User
  alias CMS.Model.ArticleComment

  def match(:account) do
    {:ok,
     %{
       model: User,
       foreign_key: :account_id,
       preload: :account,
       default_meta: Accounts.Embeds.UserMeta.default_meta()
     }}
  end

  def match(:article_comment) do
    {:ok,
     %{
       model: ArticleComment,
       foreign_key: :article_comment_id,
       preload: :article_comment,
       default_meta: CMS.Model.Embeds.CommentMeta.default_meta()
     }}
  end

  thread_matches()
  thread_query_matches()
  comment_article_matches()
end
