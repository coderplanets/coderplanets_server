defmodule MastaniServer.CMS.Misc do
  @moduledoc """
  this module defined the matches and handy guard ...
  """
  import Ecto.Query, warn: false

  alias MastaniServer.CMS.{
    Community,
    Post,
    PostFavorite,
    PostStar,
    PostComment,
    Tag,
    Community,
    PostCommentLike,
    PostCommentDislike
  }

  @support_part [:post, :video, :job]
  @support_react [:favorite, :star, :watch, :comment, :tag, :self]

  defguard valid_part(part) when part in @support_part
  defguard invalid_part(part) when part not in @support_part

  defguard valid_reaction(part, react)
           when valid_part(part) and react in @support_react

  defguard invalid_reaction(part, react)
           when invalid_part(part) and react not in @support_react

  defguard valid_feeling(feel) when feel in [:like, :dislike]

  def match_action(:post, :self), do: {:ok, %{target: Post, reactor: Post, preload: :author}}

  def match_action(:post, :favorite),
    do: {:ok, %{target: Post, reactor: PostFavorite, preload: :user, preload_right: :post}}

  def match_action(:post, :star), do: {:ok, %{target: Post, reactor: PostStar, preload: :user}}

  # defp match_action(:post, :tag), do: {:ok, %{target: Post, reactor: PostTag}}
  def match_action(:post, :tag), do: {:ok, %{target: Post, reactor: Tag}}
  def match_action(:post, :community), do: {:ok, %{target: Post, reactor: Community}}

  def match_action(:post, :comment),
    do: {:ok, %{target: Post, reactor: PostComment, preload: :author}}

  def match_action(:post_comment, :like),
    do: {:ok, %{target: PostCommentLike, reactor: PostCommentLike}}

  def match_action(:post_comment, :dislike),
    do: {:ok, %{target: PostCommentDislike, reactor: PostCommentDislike}}

  def dynamic_where(part, id) do
    case part do
      :post ->
        {:ok, dynamic([p], p.post_id == ^id)}

      :post_comment ->
        {:ok, dynamic([p], p.post_comment_id == ^id)}

      :job ->
        {:ok, dynamic([p], p.job_id == ^id)}

      :meetup ->
        {:ok, dynamic([p], p.meetup_id == ^id)}

      _ ->
        {:error, 'where is not match'}
    end
  end
end
