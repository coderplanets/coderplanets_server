defmodule MastaniServer.CMS.Utils.Matcher do
  @moduledoc """
  this module defined the matches and handy guard ...
  """
  import Ecto.Query, warn: false

  alias MastaniServer.CMS.{
    Community,
    Post,
    Video,
    Repo,
    Job,
    PostFavorite,
    JobFavorite,
    PostStar,
    JobStar,
    PostComment,
    JobComment,
    Tag,
    Community,
    PostCommentLike,
    PostCommentDislike
  }

  @support_thread [:post, :video, :repo, :job]
  @support_react [:favorite, :star, :watch, :comment, :tag, :self]

  defguard valid_thread(thread) when thread in @support_thread
  defguard invalid_thread(thread) when thread not in @support_thread

  defguard valid_reaction(thread, react)
           when valid_thread(thread) and react in @support_react

  defguard invalid_reaction(thread, react)
           when invalid_thread(thread) and react not in @support_react

  defguard valid_feeling(feel) when feel in [:like, :dislike]

  # posts ...
  def match_action(:post, :self), do: {:ok, %{target: Post, reactor: Post, preload: :author}}

  def match_action(:post, :favorite),
    do: {:ok, %{target: Post, reactor: PostFavorite, preload: :user, preload_right: :post}}

  def match_action(:post, :star), do: {:ok, %{target: Post, reactor: PostStar, preload: :user}}
  def match_action(:post, :tag), do: {:ok, %{target: Post, reactor: Tag}}
  def match_action(:post, :community), do: {:ok, %{target: Post, reactor: Community}}

  def match_action(:post, :comment),
    do: {:ok, %{target: Post, reactor: PostComment, preload: :author}}

  def match_action(:post_comment, :like),
    do: {:ok, %{target: PostComment, reactor: PostCommentLike}}

  def match_action(:post_comment, :dislike),
    do: {:ok, %{target: PostComment, reactor: PostCommentDislike}}

  # videos ...
  def match_action(:video, :community), do: {:ok, %{target: Video, reactor: Community}}

  # repos ...
  def match_action(:repo, :community), do: {:ok, %{target: Repo, reactor: Community}}

  # jobs ...
  def match_action(:job, :self), do: {:ok, %{target: Job, reactor: Job, preload: :author}}
  def match_action(:job, :community), do: {:ok, %{target: Job, reactor: Community}}
  def match_action(:job, :star), do: {:ok, %{target: Job, reactor: JobStar, preload: :user}}
  def match_action(:job, :tag), do: {:ok, %{target: Job, reactor: Tag}}

  def match_action(:job, :comment),
    do: {:ok, %{target: Job, reactor: JobComment, preload: :author}}

  def match_action(:job, :favorite),
    do: {:ok, %{target: Job, reactor: JobFavorite, preload: :user}}

  def dynamic_where(thread, id) do
    case thread do
      :post ->
        {:ok, dynamic([p], p.post_id == ^id)}

      :post_comment ->
        {:ok, dynamic([p], p.post_comment_id == ^id)}

      :job ->
        {:ok, dynamic([p], p.job_id == ^id)}

      :job_comment ->
        {:ok, dynamic([p], p.job_comment_id == ^id)}

      :meetup ->
        {:ok, dynamic([p], p.meetup_id == ^id)}

      _ ->
        {:error, 'where is not match'}
    end
  end
end
