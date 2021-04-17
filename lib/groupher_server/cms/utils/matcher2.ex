defmodule GroupherServer.CMS.Utils.Matcher2 do
  @moduledoc """
  this module defined the matches and handy guard ...
  """

  import Ecto.Query, warn: false

  alias GroupherServer.CMS

  alias CMS.{ArticleComment, Post, Job}

  def match(:article_comment) do
    {:ok, %{model: ArticleComment, foreign_key: :article_comment_id}}
  end

  def match(:post) do
    {:ok, %{model: Post, foreign_key: :post_id}}
  end

  def match(:job) do
    {:ok, %{model: Job, foreign_key: :job_id}}
  end

  def match(:post, :query, id), do: {:ok, dynamic([c], c.post_id == ^id)}
  def match(:job, :query, id), do: {:ok, dynamic([c], c.job_id == ^id)}
end
