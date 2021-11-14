defmodule Helper.ErrorCode do
  @moduledoc """
  error code map for all site
  """
  @default_base 4000
  @changeset_base 4100
  @throttle_base 4200
  @account_base 4300
  @comment_base 4400
  @article_base 4500

  @spec raise_error(Atom.t(), String.t()) :: {:error, [message: String.t(), code: Integer.t()]}
  def raise_error(code_atom, msg) do
    {:error, [message: msg, code: ecode(code_atom)]}
  end

  # account error code
  def ecode(:account_login), do: @account_base + 1
  def ecode(:passport), do: @account_base + 2
  # ...
  # changeset error code
  def ecode(:changeset), do: @changeset_base + 2
  # default errors
  def ecode(:custom), do: @default_base + 1
  def ecode(:pagination), do: @default_base + 2
  def ecode(:not_exsit), do: @default_base + 3
  def ecode(:already_did), do: @default_base + 4
  def ecode(:self_conflict), do: @default_base + 5
  def ecode(:react_fails), do: @default_base + 6
  def ecode(:already_exsit), do: @default_base + 7
  def ecode(:update_fails), do: @default_base + 8
  def ecode(:delete_fails), do: @default_base + 9
  def ecode(:create_fails), do: @default_base + 10
  def ecode(:exsit_pending_bill), do: @default_base + 11
  def ecode(:bill_state), do: @default_base + 12
  def ecode(:bill_action), do: @default_base + 13
  def ecode(:editor_data_parse), do: @default_base + 14
  def ecode(:community_exist), do: @default_base + 15
  # throttle
  def ecode(:throttle_inverval), do: @throttle_base + 1
  def ecode(:throttle_hour), do: @throttle_base + 2
  def ecode(:throttle_day), do: @throttle_base + 3
  # comment
  def ecode(:create_comment), do: @comment_base + 1
  def ecode(:comment_already_upvote), do: @comment_base + 2
  # article
  def ecode(:too_much_pinned_article), do: @article_base + 1
  def ecode(:already_collected_in_folder), do: @article_base + 2
  def ecode(:delete_no_empty_collect_folder), do: @article_base + 3
  def ecode(:private_collect_folder), do: @article_base + 4
  def ecode(:mirror_article), do: @article_base + 5
  def ecode(:invalid_domain_tag), do: @article_base + 6
  def ecode(:undo_sink_old_article), do: @article_base + 7
  def ecode(:article_comments_locked), do: @article_base + 8
  def ecode(:require_questioner), do: @article_base + 9
  def ecode(:cite_artilce), do: @article_base + 10
  def ecode(:archived), do: @article_base + 11
  def ecode(:invalid_blog_rss), do: @article_base + 12
  def ecode(:invalid_blog_title), do: @article_base + 13
  # def ecode(:already_solved), do: @article_base + 10
  def ecode(:already_upvoted), do: @article_base + 14
  def ecode(:pending), do: @article_base + 15

  def ecode, do: @default_base
  # def ecode(_), do: @default_base
end
