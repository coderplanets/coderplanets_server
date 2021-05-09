defmodule GroupherServer.CMS.Helper.Matcher do
  @moduledoc """
  this module defined the matches and handy guard ...
  """
  import Ecto.Query, warn: false

  alias GroupherServer.CMS.{
    Community,
    # threads
    Post,
    Repo,
    Job,
    # viewer
    # reactions
    # comments
    PostComment,
    # commtnes reaction
    PostCommentLike,
    #
    Tag,
    Community,
    # flags
    PostCommunityFlag,
    JobCommunityFlag,
    RepoCommunityFlag
  }

  #########################################
  ##  posts ...
  #########################################
  def match_action(:post, :self),
    do: {:ok, %{target: Post, reactor: Post, preload: :author}}

  def match_action(:post, :tag), do: {:ok, %{target: Post, reactor: Tag}}
  # NOTE: the tech, radar, share, city thread also use common tag
  def match_action(:radar, :tag), do: {:ok, %{target: Post, reactor: Tag}}
  def match_action(:share, :tag), do: {:ok, %{target: Post, reactor: Tag}}
  def match_action(:city, :tag), do: {:ok, %{target: Post, reactor: Tag}}
  def match_action(:tech, :tag), do: {:ok, %{target: Post, reactor: Tag}}

  def match_action(:post, :community),
    do: {:ok, %{target: Post, reactor: Community, flag: PostCommunityFlag}}

  def match_action(:post, :comment),
    do: {:ok, %{target: Post, reactor: PostComment, preload: :author}}

  def match_action(:post_comment, :like),
    do: {:ok, %{target: PostComment, reactor: PostCommentLike}}

  #########################################
  ## jobs ...
  #########################################
  def match_action(:job, :self),
    do: {:ok, %{target: Job, reactor: Job, preload: :author}}

  def match_action(:job, :community),
    do: {:ok, %{target: Job, reactor: Community, flag: JobCommunityFlag}}

  def match_action(:job, :tag), do: {:ok, %{target: Job, reactor: Tag}}

  #########################################
  ## repos ...
  #########################################
  def match_action(:repo, :self),
    do: {:ok, %{target: Repo, reactor: Repo, preload: :author}}

  def match_action(:repo, :community),
    do: {:ok, %{target: Repo, reactor: Community, flag: RepoCommunityFlag}}

  def match_action(:repo, :tag), do: {:ok, %{target: Repo, reactor: Tag}}

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
