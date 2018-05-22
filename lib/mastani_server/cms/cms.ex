defmodule MastaniServer.CMS do
  @moduledoc """
  this module defined basic method to handle [CMS] content [CURD] ..
  [CMS]: post, job, ...
  [CURD]: create, update, delete ...
  """
  alias MastaniServer.CMS.Delegate.{
    ArticleOperation,
    ArticleCURD,
    ArticleReaction,
    CommentReaction,
    CommentCURD,
    CommunityCURD,
    PassportCURD,
    CommunityOperation
  }

  # do not pattern match in delegating func, do it on one delegating inside
  # see https://github.com/elixir-lang/elixir/issues/5306

  # Community CURD: editors, thread, tag
  # >> community
  defdelegate create_community(attrs), to: CommunityCURD
  defdelegate update_community(attrs), to: CommunityCURD
  # >> editor ..
  defdelegate update_editor(user_id, community_id, title), to: CommunityCURD
  defdelegate delete_editor(user_id, community_id), to: CommunityCURD
  # >> subscribers / editors
  defdelegate community_members(type, community_id, filters), to: CommunityCURD
  # >> category
  defdelegate create_category(category_title, user_id), to: CommunityCURD
  defdelegate update_category(category_attrs), to: CommunityCURD
  # >> thread
  defdelegate create_thread(attrs), to: CommunityCURD
  # >> tag
  defdelegate create_tag(part, attrs, user_id), to: CommunityCURD
  defdelegate get_tags(community_title, part), to: CommunityCURD
  defdelegate get_tags(filter), to: CommunityCURD

  # CommunityOperation
  # >> editor
  defdelegate add_editor_to_community(user_id, community_id, title), to: CommunityOperation
  # >> thread
  defdelegate add_thread_to_community(attrs), to: CommunityOperation
  # >> subscribe / unsubscribe
  defdelegate subscribe_community(user_id, community_id), to: CommunityOperation
  defdelegate unsubscribe_community(user_id, community_id), to: CommunityOperation

  # ArticleCURD
  defdelegate create_content(part, author_id, attrs), to: ArticleCURD
  defdelegate reaction_users(part, react, id, filters), to: ArticleCURD

  # ArticleReaction
  defdelegate reaction(part, react, part_id, user_id), to: ArticleReaction
  defdelegate undo_reaction(part, react, part_id, user_id), to: ArticleReaction

  # ArticleOperation
  # >> tag: set / unset
  defdelegate set_tag(community_title, part, part_id, tag_id), to: ArticleOperation
  defdelegate unset_tag(part, part_id, tag_id), to: ArticleOperation
  # >> community: set / unset
  defdelegate set_community(part, part_id, community_title), to: ArticleOperation
  defdelegate unset_community(part, part_id, community_title), to: ArticleOperation
  # >> reaction

  # Comment CURD
  defdelegate create_comment(part, part_id, user_id, body), to: CommentCURD
  defdelegate delete_comment(part, part_id), to: CommentCURD
  defdelegate list_comments(part, part_id, filters), to: CommentCURD
  defdelegate list_replies(part, comment_id, user_id), to: CommentCURD
  defdelegate reply_comment(part, comment_id, user_id, body), to: CommentCURD

  # Comment Reaction
  # >> like / undo like
  defdelegate like_comment(part, comment_id, user_id), to: CommentReaction
  defdelegate undo_like_comment(part, comment_id, user_id), to: CommentReaction
  # >> dislike / undo dislike
  defdelegate dislike_comment(part, comment_id, user_id), to: CommentReaction
  defdelegate undo_dislike_comment(part, comment_id, user_id), to: CommentReaction

  # Passport CURD
  defdelegate stamp_passport(user_id, rules), to: PassportCURD
  defdelegate erase_passport(user_id, rules), to: PassportCURD
  defdelegate get_passport(user_id), to: PassportCURD
  defdelegate list_passports(community, key), to: PassportCURD
  defdelegate delete_passport(user_id), to: PassportCURD
end
