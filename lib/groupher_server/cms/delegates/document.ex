defmodule GroupherServer.CMS.Delegate.Document do
  @moduledoc """
  CURD operation on post/job ...
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [thread_of: 2]

  import Helper.ErrorCode

  alias Helper.{ORM, Converter}
  alias GroupherServer.{CMS, Repo}

  alias CMS.Model.ArticleDocument
  alias Ecto.Multi

  # alias Helper.Converter.MdToEditor
  alias GroupherServer.Support.Factory

  # TODO: spec repo logic
  def create(article, %{readme: readme} = attrs) do
    # .parse(markdown)
    # body = MdToEditor.mock_rich_text(readme)
    body = Factory.mock_rich_text(readme)
    attrs = attrs |> Map.drop([:readme]) |> Map.put(:body, body)
    create(article, attrs)
  end

  #  for create artilce step in Multi.new
  def create(article, %{body: body}) do
    with {:ok, article_thread} <- thread_of(article, :upcase),
         false <- article_document_exist(article),
         {:ok, parsed} <- Converter.Article.parse_body(body) do
      attrs = Map.take(parsed, [:body, :body_html])

      Multi.new()
      |> Multi.run(:create_article_document, fn _, _ ->
        document_attrs =
          Map.merge(attrs, %{
            thread: article_thread,
            article_id: article.id,
            title: article.title
          })

        ArticleDocument |> ORM.create(document_attrs)
      end)
      |> Multi.run(:create_thread_document, fn _, _ ->
        attrs = attrs |> Map.put(foreign_key(article_thread), article.id)

        CMS.Model
        |> Module.concat("#{Recase.to_title(article_thread)}Document")
        |> ORM.create(attrs)
      end)
      |> Repo.transaction()
      |> result()
    else
      true ->
        {:error, "document already exist"}
    end
  end

  defp article_document_exist(article) do
    with {:ok, article_thread} <- thread_of(article, :upcase) do
      {:ok, count} =
        ArticleDocument
        |> where([ad], ad.thread == ^article_thread and ad.article_id == ^article.id)
        |> ORM.count()

      count > 0
    end
  end

  @doc """
  update both article and thread document
  """
  def update(article, %{body: body} = attrs) when not is_nil(body) do
    with {:ok, article_thread} <- thread_of(article, :upcase),
         {:ok, article_doc} <- find_article_document(article_thread, article),
         {:ok, thread_doc} <- find_thread_document(article_thread, article),
         {:ok, parsed} <- Converter.Article.parse_body(body) do
      attrs = Map.take(parsed, [:body, :body_html])

      Multi.new()
      |> Multi.run(:update_article_document, fn _, _ ->
        case Map.has_key?(attrs, :title) do
          true -> article_doc |> ORM.update(Map.merge(attrs, %{title: attrs.title}))
          false -> article_doc |> ORM.update(attrs)
        end
      end)
      |> Multi.run(:update_thread_document, fn _, _ ->
        thread_doc |> ORM.update(attrs)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  # 只更新 title 的情况
  def update(article, %{title: title} = attrs) do
    with {:ok, article_thread} <- thread_of(article, :upcase),
         {:ok, article_doc} <- find_article_document(article_thread, article) do
      article_doc |> ORM.update(%{title: attrs.title})
    end
  end

  def update(article, _), do: {:ok, article}

  defp find_article_document(article_thread, article) do
    ORM.find_by(ArticleDocument, %{article_id: article.id, thread: article_thread})
  end

  defp find_thread_document(article_thread, article) do
    CMS.Model
    |> Module.concat("#{Recase.to_title(article_thread)}Document")
    |> ORM.find_by(Map.put(%{}, foreign_key(article_thread), article.id))
  end

  @doc """
  remove article document foever
  """
  def remove(thread, id) do
    thread = thread |> to_string |> String.upcase()

    ArticleDocument |> ORM.findby_delete!(%{thread: thread, article_id: id})
  end

  defp foreign_key(article_thread) do
    thread_atom = article_thread |> String.downcase() |> String.to_atom()

    :"#{thread_atom}_id"
  end

  defp result({:ok, %{create_thread_document: result}}), do: {:ok, result}
  defp result({:ok, %{update_article_document: result}}), do: {:ok, result}

  defp result({:error, _, _result, _steps}) do
    {:error, [message: "create document", code: ecode(:create_fails)]}
  end
end
