defmodule GroupherServer.CMS.Helper.Matcher2 do
  @moduledoc """
  this module defined the matches and handy guard ...
  """

  import Ecto.Query, warn: false

  alias GroupherServer.CMS

  alias CMS.{ArticleComment, Post, Job, Repo}

  def match(:article_comment) do
    {:ok, %{model: ArticleComment, foreign_key: :article_comment_id}}
  end

  def match(:comment_article, %ArticleComment{post_id: post_id}) when not is_nil(post_id) do
    {:ok, %{model: Post, id: post_id, foreign_key: :post_id}}
  end

  def match(:comment_article, %ArticleComment{job_id: job_id}) when not is_nil(job_id) do
    {:ok, %{model: Job, id: job_id, foreign_key: :job_id}}
  end

  def match(:comment_article, %ArticleComment{}) do
    {:error, "not supported"}
  end

  # used for paged pin articles
  def match(Post) do
    {:ok, %{thread: :post}}
  end

  def match(:post) do
    {:ok, %{model: Post, foreign_key: :post_id}}
  end

  def match(Job) do
    {:ok, %{thread: :job}}
  end

  def match(:job) do
    {:ok, %{model: Job, foreign_key: :job_id}}
  end

  def match(Repo) do
    {:ok, %{thread: :repo}}
  end

  def match(:repo) do
    {:ok, %{model: Repo, foreign_key: :repo_id}}
  end

  def match(:post, :query, id), do: {:ok, dynamic([c], c.post_id == ^id)}
  def match(:job, :query, id), do: {:ok, dynamic([c], c.job_id == ^id)}
end