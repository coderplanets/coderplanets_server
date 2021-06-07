defmodule GroupherServer.CMS.Helper.MatcherOld do
  @moduledoc """
  this module defined the matches and handy guard ...
  """
  import Ecto.Query, warn: false

  alias GroupherServer.CMS.Model.{
    Community,
    # threads
    Post,
    Repo,
    Job,
    Blog,
    # viewer
    # reactions
    # comments
    PostComment,
    # commtnes reaction
    PostCommentLike,
    #
    Community
  }

  #########################################
  ##  posts ...
  #########################################
  def match_action(:post, :self),
    do: {:ok, %{target: Post, reactor: Post, preload: :author}}

  def match_action(:post, :community),
    do: {:ok, %{target: Post, reactor: Community}}

  def match_action(:post, :comment),
    do: {:ok, %{target: Post, reactor: PostComment, preload: :author}}

  #########################################
  ## jobs ...
  #########################################
  def match_action(:job, :self),
    do: {:ok, %{target: Job, reactor: Job, preload: :author}}

  def match_action(:job, :community),
    do: {:ok, %{target: Job, reactor: Community}}

  def match_action(:blog, :self),
    do: {:ok, %{target: Blog, reactor: Blog, preload: :author}}

  def match_action(:blog, :community),
    do: {:ok, %{target: Blog, reactor: Community}}

  #########################################
  ## repos ...
  #########################################
  def match_action(:repo, :self),
    do: {:ok, %{target: Repo, reactor: Repo, preload: :author}}

  def match_action(:repo, :community),
    do: {:ok, %{target: Repo, reactor: Community}}

  # dynamic where query match
  def dynamic_where(thread, id) do
    case thread do
      :post ->
        {:ok, dynamic([p], p.post_id == ^id)}

      :post_comment ->
        {:ok, dynamic([p], p.post_comment_id == ^id)}

      :job ->
        {:ok, dynamic([p], p.job_id == ^id)}

      :repo ->
        {:ok, dynamic([p], p.repo_id == ^id)}

      _ ->
        {:error, 'where is not match'}
    end
  end
end
