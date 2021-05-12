defmodule GroupherServer.CMS.Delegate.AbuseReport do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, strip_struct: 1]

  import GroupherServer.CMS.Helper.Matcher2
  import ShortMaps

  alias Helper.ORM
  alias Helper.QueryBuilder
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.User
  alias CMS.{AbuseReport, ArticleComment, Embeds}

  alias Ecto.Multi

  # filter = %{
  #   contentType: account | post | job | repo | article_comment | community
  #   contentId: ...
  #   operate_user_id,
  #   min_case_count,
  #   max_case_count,
  #   is_closed
  #   page
  #   size
  # }

  @article_threads [:post, :job, :repo]
  @export_author_keys [:id, :login, :nickname, :avatar]
  @export_article_keys [:id, :title, :digest, :upvotes_count, :views]
  @export_report_keys [
    :id,
    :deal_with,
    :is_closed,
    :operate_user,
    :report_cases,
    :report_cases_count,
    :inserted_at,
    :updated_at
  ]

  @doc """
  list paged reports for article comemnts
  """
  def list_reports(%{content_type: :user, content_id: content_id} = filter) do
    %{page: page, size: size} = filter

    with {:ok, info} <- match(:account_user) do
      query =
        from(r in AbuseReport,
          where: field(r, ^info.foreign_key) == ^content_id,
          preload: :account
        )

      query
      |> QueryBuilder.filter_pack(filter)
      |> ORM.paginater(~m(page size)a)
      |> reports_formater(:account_user)
      |> done()
    end
  end

  @doc """
  list paged reports for article comemnts
  """
  def list_reports(%{content_type: :article_comment, content_id: content_id} = filter) do
    %{page: page, size: size} = filter

    with {:ok, info} <- match(:article_comment) do
      query =
        from(r in AbuseReport,
          where: field(r, ^info.foreign_key) == ^content_id,
          preload: [article_comment: ^@article_threads],
          preload: [article_comment: :author]
        )

      query
      |> QueryBuilder.filter_pack(filter)
      |> ORM.paginater(~m(page size)a)
      |> reports_formater(:article_comment)
      |> done()
    end
  end

  @doc """
  list paged reports for article
  """
  def list_reports(%{content_type: thread, content_id: content_id} = filter)
      when thread in @article_threads do
    %{page: page, size: size} = filter

    with {:ok, info} <- match(thread) do
      query =
        from(r in AbuseReport,
          where: field(r, ^info.foreign_key) == ^content_id,
          preload: [^thread, :operate_user]
        )

      query
      |> QueryBuilder.filter_pack(filter)
      |> ORM.paginater(~m(page size)a)
      |> reports_formater(thread)
      |> done()
    end
  end

  def report_account(account_id, reason, attr, user) do
    with {:ok, info} <- match(:account_user),
         {:ok, account} <- ORM.find(info.model, account_id) do
      Multi.new()
      |> Multi.run(:create_abuse_report, fn _, _ ->
        create_report(:account_user, account.id, reason, attr, user)
      end)
      |> Multi.run(:update_report_flag, fn _, _ ->
        update_report_meta(info, account)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc """
  undo report article content
  """
  def undo_report_account(account_id, %User{} = user) do
    with {:ok, info} <- match(:account_user),
         {:ok, account} <- ORM.find(info.model, account_id) do
      Multi.new()
      |> Multi.run(:delete_abuse_report, fn _, _ ->
        delete_report(:account_user, account.id, user)
      end)
      |> Multi.run(:update_report_flag, fn _, _ ->
        update_report_meta(info, account)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc """
  report article content
  """
  def report_article(thread, article_id, reason, attr, %User{} = user) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id) do
      Multi.new()
      |> Multi.run(:create_abuse_report, fn _, _ ->
        create_report(thread, article.id, reason, attr, user)
      end)
      |> Multi.run(:update_report_flag, fn _, _ ->
        update_report_meta(info, article)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc """
  undo report article content
  """
  def undo_report_article(thread, article_id, %User{} = user) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id) do
      Multi.new()
      |> Multi.run(:delete_abuse_report, fn _, _ ->
        delete_report(thread, article.id, user)
      end)
      |> Multi.run(:update_report_flag, fn _, _ ->
        update_report_meta(info, article)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  def undo_report_article_comment(comment_id, %User{} = user) do
    undo_report_article(:article_comment, comment_id, user)
  end

  def create_report(type, content_id, reason, attr, %User{} = user) do
    with {:ok, info} <- match(type),
         {:ok, report} <- not_reported_before(info, content_id, user) do
      case report do
        nil ->
          report_cases = [
            %{
              reason: reason,
              attr: attr,
              user: %{login: user.login, nickname: user.nickname}
            }
          ]

          args =
            %{report_cases_count: 1, report_cases: report_cases}
            |> Map.put(info.foreign_key, content_id)

          AbuseReport |> ORM.create(args)

        _ ->
          user = %{login: user.login, nickname: user.nickname}

          report_cases =
            report.report_cases
            |> List.insert_at(
              length(report.report_cases),
              %Embeds.AbuseReportCase{reason: reason, attr: attr, user: user}
            )

          report
          |> Ecto.Changeset.change(%{report_cases_count: length(report_cases)})
          |> Ecto.Changeset.put_embed(:report_cases, report_cases)
          |> Repo.update()
      end
    end
  end

  defp delete_report(thread, content_id, %User{} = user) do
    with {:ok, info} <- match(thread),
         {:error, _} <- not_reported_before(info, content_id, user),
         {:ok, report} = ORM.find_by(AbuseReport, Map.put(%{}, info.foreign_key, content_id)) do
      case length(report.report_cases) do
        1 ->
          ORM.delete(report)

        _ ->
          report_cases = report.report_cases |> Enum.reject(&(&1.user.login == user.login))

          report
          |> Ecto.Changeset.change(%{report_cases_count: length(report_cases)})
          |> Ecto.Changeset.put_embed(:report_cases, report_cases)
          |> Repo.update()
      end
    end
  end

  # update  reported_count in mete for article or comment
  defp update_report_meta(info, content) do
    case ORM.find_by(AbuseReport, Map.put(%{}, info.foreign_key, content.id)) do
      {:ok, record} ->
        reported_count = record.report_cases |> length

        safe_meta = if is_nil(content.meta), do: info.default_meta, else: content.meta
        meta = safe_meta |> Map.merge(%{reported_count: reported_count}) |> strip_struct

        content
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_embed(:meta, meta)
        |> Repo.update()

      {:error, _} ->
        safe_meta = if is_nil(content.meta), do: info.default_meta, else: content.meta
        meta = safe_meta |> Map.merge(%{reported_count: 0}) |> strip_struct

        content
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_embed(:meta, meta)
        |> Repo.update()
    end
  end

  defp not_reported_before(info, content_id, %User{login: login}) do
    query = from(r in AbuseReport, where: field(r, ^info.foreign_key) == ^content_id)

    report = Repo.one(query)

    case report do
      nil ->
        {:ok, nil}

      _ ->
        reported_before =
          report.report_cases
          |> Enum.filter(fn item -> item.user.login == login end)
          |> length
          |> Kernel.>(0)

        if not reported_before, do: {:ok, report}, else: {:error, "#{login} already reported"}
    end
  end

  defp reports_formater(%{entries: entries} = paged_reports, :account_user) do
    paged_reports
    |> Map.put(
      :entries,
      Enum.map(entries, fn report ->
        basic_report = report |> Map.take(@export_report_keys)
        basic_report |> Map.put(:account, extract_account_info(report))
      end)
    )
  end

  defp reports_formater(%{entries: entries} = paged_reports, :article_comment) do
    paged_reports
    |> Map.put(
      :entries,
      Enum.map(entries, fn report ->
        basic_report = report |> Map.take(@export_report_keys)
        basic_report |> Map.put(:article_comment, extract_article_comment_info(report))
      end)
    )
  end

  defp reports_formater(%{entries: entries} = paged_reports, thread)
       when thread in @article_threads do
    paged_reports
    |> Map.put(
      :entries,
      Enum.map(entries, fn report ->
        basic_report = report |> Map.take(@export_report_keys)
        basic_report |> Map.put(:article, extract_article_info(thread, report))
      end)
    )
  end

  defp extract_account_info(%AbuseReport{} = report) do
    account = report |> Map.get(:account) |> Map.take(@export_author_keys)
  end

  # TODO: original community and communities info
  defp extract_article_info(thread, %AbuseReport{} = report) do
    report
    |> Map.get(thread)
    |> Map.take(@export_article_keys)
    |> Map.merge(%{thread: thread})
  end

  def extract_article_comment_info(%AbuseReport{} = report) do
    keys = [:id, :upvotes_count, :body_html]
    author = Map.take(report.article_comment.author, @export_author_keys)

    comment = Map.take(report.article_comment, keys)
    comment = Map.merge(comment, %{author: author})

    article = extract_article_in_comment(report.article_comment)
    Map.merge(comment, %{article: article})
  end

  defp extract_article_in_comment(%ArticleComment{} = article_comment) do
    article_thread =
      Enum.filter(@article_threads, fn thread ->
        not is_nil(Map.get(article_comment, :"#{thread}_id"))
      end)
      |> List.first()

    article_comment
    |> Map.get(article_thread)
    |> Map.take(@export_article_keys)
    |> Map.merge(%{thread: article_thread})
  end

  defp result({:ok, %{update_report_flag: result}}), do: result |> done()

  defp result({:error, _, result, _steps}) do
    {:error, result}
  end
end
