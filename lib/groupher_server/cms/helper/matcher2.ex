defmodule GroupherServer.CMS.Helper.Matcher2.Macros do
  @moduledoc """
  generate match functions
  """

  alias GroupherServer.CMS
  alias CMS.{Community, Embeds}

  @article_threads Community.article_threads()

  defmacro thread_matchs() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        def match(unquote(thread)) do
          thread_module = unquote(thread) |> to_string |> Recase.to_pascal()

          {:ok,
           %{
             model: Module.concat(CMS, thread_module),
             thread: unquote(thread),
             foreign_key: unquote(:"#{thread}_id"),
             preload: unquote(thread),
             default_meta: Embeds.ArticleMeta.default_meta()
           }}
        end

        # def match(Module.concat(CMS, Recase.to_pascal(unquote(thread)))) do
        #   {:ok, %{thread: :post}}
        # end
      end
    end)
  end
end

defmodule GroupherServer.CMS.Helper.Matcher2 do
  @moduledoc """
  this module defined the matches and handy guard ...
  """

  import Ecto.Query, warn: false
  import GroupherServer.CMS.Helper.Matcher2.Macros

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.User
  alias CMS.{ArticleComment, Post, Job, Repo}

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
       default_meta: CMS.Embeds.ArticleCommentMeta.default_meta()
     }}
  end

  def match(:comment_article, %ArticleComment{post_id: post_id}) when not is_nil(post_id) do
    {:ok, %{model: Post, id: post_id, foreign_key: :post_id}}
  end

  def match(:comment_article, %ArticleComment{job_id: job_id}) when not is_nil(job_id) do
    {:ok, %{model: Job, id: job_id, foreign_key: :job_id}}
  end

  def match(:comment_article, %ArticleComment{repo_id: repo_id}) when not is_nil(repo_id) do
    {:ok, %{model: Repo, id: repo_id, foreign_key: :repo_id}}
  end

  def match(:comment_article, %ArticleComment{}) do
    {:error, "match error, not supported"}
  end

  thread_matchs()

  def match(:post, :query, id), do: {:ok, dynamic([c], c.post_id == ^id)}
  def match(:job, :query, id), do: {:ok, dynamic([c], c.job_id == ^id)}
end
