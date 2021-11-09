defmodule GroupherServer.CMS.Helper.Matcher do
  @moduledoc """
  this module defined the matches and handy guard ...
  """

  import Ecto.Query, warn: false
  import GroupherServer.CMS.Helper.MatcherMacros

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.Model.User
  alias CMS.Model.Comment

  def match(:account) do
    {:ok,
     %{
       model: User,
       foreign_key: :account_id,
       preload: :account,
       default_meta: Accounts.Model.Embeds.UserMeta.default_meta()
     }}
  end

  def match(:comment) do
    {:ok,
     %{
       model: Comment,
       foreign_key: :comment_id,
       preload: :comment,
       default_meta: CMS.Model.Embeds.CommentMeta.default_meta()
     }}
  end

  thread_matches()
  thread_query_matches()
end
