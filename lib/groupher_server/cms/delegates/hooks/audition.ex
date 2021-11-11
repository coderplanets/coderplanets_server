defmodule GroupherServer.CMS.Delegate.Hooks.Audition do
  @moduledoc """
  hooks for mention task

  parse and fmt(see shape function) mentions to Delivery module
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{CMS, Repo}
  alias Helper.AuditBot

  def handle(%{body: body} = artiment) do
    IO.inspect(artiment, label: "handle Audition")

    with {:ok, %{"blocks" => blocks}} <- Jason.decode(body) do
      #  {:ok, artiment} <- preload_author(artiment) do
      # blocks
      # |> Enum.reduce([], &(&2 ++ parse_mention_info_per_block(artiment, &1)))
      # |> merge_same_block_linker(:to_user_id)
      # |> handle_mentions(artiment)
    end
  end

  def handle(%{title: title, document: _document} = article) do
    body_html = Repo.preload(article, :document) |> get_in([:document, :body_html])
    audit_text = title <> body_html

    AuditBot.analysis(:text, audit_text) |> handle_audition_result(article)
  end

  # NOTE: this method is only for test
  def handle_edge(%{title: title, document: _document} = article) do
    body_html = Repo.preload(article, :document) |> get_in([:document, :body_html])
    audit_text = title <> body_html

    AuditBot.analysis_wrong(:text, audit_text)
    |> handle_audition_result(article)
  end

  def handle_audition_result({:ok, audit_res}, article) do
    audit_res = Map.merge(audit_res, %{illegal_articles: []})
    CMS.unset_article_illegal(article, audit_res)
  end

  def handle_audition_result({:error, %{audit_failed: true} = audit_res}, article) do
    CMS.set_article_audit_failed(article, audit_res)
  end

  def handle_audition_result({:error, audit_res}, article) do
    article_addr = "/#{String.downcase(article.meta.thread)}/#{article.id}"
    illegal_articles = [article_addr]

    audit_res = Map.merge(audit_res, %{illegal_articles: illegal_articles})
    CMS.set_article_illegal(article, audit_res)
  end
end
