defmodule GroupherServerWeb.Schema.CMS.Types do
  @moduledoc """
  cms types used in queries & mutations
  """
  use Helper.GqlSchemaSuite

  import GroupherServerWeb.Schema.Helper.Fields
  import GroupherServerWeb.Schema.Helper.Objects

  import Ecto.Query, warn: false
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  alias GroupherServer.CMS
  alias GroupherServerWeb.Schema

  import_types(Schema.CMS.Metrics)

  ######
  # common stands for minimal info of the type
  # usually used in abuse_report, feeds, etc ..
  object :common_user do
    field(:login, :string)
    field(:nickname, :string)
    field(:avatar, :string)
  end

  object :common_article do
    field(:thread, :string)
    field(:id, :id)
    # field(:body_html, :string)
    field(:title, :string)
    field(:author, :common_user)
  end

  object :common_comment do
    field(:id, :id)
    field(:body_html, :string)
    field(:upvotes_count, :integer)
    field(:author, :common_user)
    field(:article, :common_article)
  end

  ######

  object :idlike do
    field(:id, :id)
  end

  object :simple_user do
    field(:login, :string)
    field(:nickname, :string)
  end

  object :post do
    meta(:cache, max_age: 30)
    interface(:article)

    general_article_fields()
    comments_fields()

    field(:length, :integer)
    field(:link_addr, :string)
    field(:copy_right, :string)

    timestamp_fields(:article)
  end

  object :job do
    interface(:article)

    general_article_fields()
    comments_fields()

    field(:desc, :string)
    field(:company, :string)
    field(:company_link, :string)
    field(:length, :integer)
    field(:link_addr, :string)
    field(:copy_right, :string)

    timestamp_fields(:article)
  end

  object :blog do
    interface(:article)

    general_article_fields()
    comments_fields()

    field(:length, :integer)
    field(:link_addr, :string)

    timestamp_fields(:article)
  end

  object :repo do
    interface(:article)

    general_article_fields()
    comments_fields()

    field(:owner_name, :string)
    field(:owner_url, :string)
    field(:repo_url, :string)

    field(:desc, :string)
    field(:homepage_url, :string)
    field(:readme, :string)

    field(:star_count, :integer)
    field(:issues_count, :integer)
    field(:prs_count, :integer)
    field(:fork_count, :integer)
    field(:watch_count, :integer)

    field(:primary_language, :repo_lang)
    field(:license, :string)
    field(:release_tag, :string)

    field(:contributors, list_of(:repo_contributor))

    field(:last_sync, :datetime)

    timestamp_fields(:article)
  end

  object :repo_contributor do
    field(:avatar, :string)
    field(:html_url, :string)
    field(:nickname, :string)
  end

  object :repo_lang do
    field(:name, :string)
    field(:color, :string)
  end

  object :github_contributor do
    field(:avatar, :string)
    field(:bio, :string)
    field(:html_url, :string)
    field(:nickname, :string)
    field(:location, :string)
    field(:company, :string)
  end

  object :wiki do
    field(:id, :id)
    field(:readme, :string)
    field(:contributors, list_of(:github_contributor))

    field(:last_sync, :datetime)
    field(:views, :integer)

    timestamp_fields()
  end

  object :cheatsheet do
    field(:id, :id)
    field(:readme, :string)
    field(:contributors, list_of(:github_contributor))

    field(:last_sync, :datetime)
    field(:views, :integer)

    timestamp_fields()
  end

  object :thread_item do
    field(:id, :id)
    field(:title, :string)
    field(:raw, :string)
    field(:index, :integer)
  end

  object :contribute do
    meta(:cache, max_age: 30)
    field(:date, :date)
    field(:count, :integer)
  end

  object :contribute_map do
    meta(:cache, max_age: 30)
    field(:start_date, :date)
    field(:end_date, :date)
    field(:total_count, :integer)
    field(:records, list_of(:contribute))
  end

  object :community do
    meta(:cache, max_age: 30)
    field(:id, :id)
    field(:title, :string)
    field(:desc, :string)
    field(:raw, :string)
    field(:index, :integer)
    field(:logo, :string)
    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:threads, list_of(:thread_item), resolve: dataloader(CMS, :threads))
    field(:categories, list_of(:category), resolve: dataloader(CMS, :categories))
    field(:meta, :community_meta)
    field(:views, :integer)

    field(:articles_count, :integer)
    field(:subscribers_count, :integer)
    field(:editors_count, :integer)
    field(:article_tags_count, :integer)

    # TODO: remove
    field :threads_count, :integer do
      resolve(&R.CMS.threads_count/3)
    end

    timestamp_fields()
  end

  object :category do
    field(:id, :id)
    field(:title, :string)
    field(:raw, :string)
    field(:index, :integer)
    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:communities, list_of(:community), resolve: dataloader(CMS, :communities))

    timestamp_fields()
  end

  object :article_tag do
    field(:id, :id)
    field(:title, :string)
    field(:color, :string)
    field(:thread, :string)
    field(:group, :string)

    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:community, :community, resolve: dataloader(CMS, :community))

    timestamp_fields()
  end

  object :comment_emotions do
    emotion_fields(:comment)
  end

  object :article_emotions do
    emotion_fields()
  end

  object :article_comment_meta do
    field(:is_article_author_upvoted, :boolean)
    field(:is_reply_to_others, :boolean)

    # field(:report_count, :boolean)
    # field(:is_solution, :boolean)
  end

  object :comment_reply do
    field(:id, :id)
    field(:body, :string)
    field(:body_html, :string)
    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:floor, :integer)
    field(:upvotes_count, :integer)
    field(:is_article_author, :boolean)
    field(:emotions, :comment_emotions)
    field(:meta, :article_comment_meta)
    field(:replies_count, :integer)
    field(:reply_to, :comment_reply)
    field(:viewer_has_upvoted, :boolean)
    field(:thread, :string)

    timestamp_fields()
  end

  object :comment do
    field(:id, :id)
    field(:body_html, :string)
    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:is_pinned, :boolean)
    field(:floor, :integer)
    field(:upvotes_count, :integer)
    field(:emotions, :comment_emotions)
    field(:is_article_author, :boolean)
    field(:meta, :article_comment_meta)
    field(:reply_to, :comment_reply)
    field(:replies, list_of(:comment_reply))
    field(:replies_count, :integer)
    field(:thread, :string)
    field(:article, :common_article)

    field(:is_deleted, :boolean)
    field(:viewer_has_upvoted, :boolean)

    field(:is_for_question, :boolean)
    field(:is_solution, :boolean)

    timestamp_fields()
  end

  ####### reports
  object :abuse_report_case do
    field(:reason, :string)
    field(:attr, :string)
    field(:user, :common_user)
  end

  object :abuse_report do
    field(:id, :id)
    field(:article, :common_article)
    field(:comment, :common_comment)
    field(:account, :common_user)
    field(:report_cases_count, :integer)
    field(:deal_with, :string)
    field(:operate_user, :user)
    field(:report_cases, list_of(:abuse_report_case))

    timestamp_fields()
  end

  paged_article_objects()

  object :paged_reports do
    field(:entries, list_of(:abuse_report))
    pagination_fields()
  end

  object :paged_categories do
    field(:entries, list_of(:category))
    pagination_fields()
  end

  object :paged_comments do
    field(:entries, list_of(:comment))
    pagination_fields()
  end

  object :paged_comment_replies do
    field(:entries, list_of(:comment_reply))
    pagination_fields()
  end

  object :paged_communities do
    field(:entries, list_of(:community))
    pagination_fields()
  end

  object :paged_article_tags do
    field(:entries, list_of(:article_tag))
    pagination_fields()
  end

  object :paged_threads do
    field(:entries, list_of(:thread_item))
    pagination_fields()
  end

  object :paged_articles do
    field(:entries, list_of(:common_article))
    pagination_fields()
  end

  @desc "article meta info"
  object :article_meta do
    field(:is_edited, :boolean)
    field(:is_comment_locked, :boolean)
    # field(:linked_posts_count, :integer)
  end

  object :community_meta do
    threads_count_fields()
    # field(:contributes_digest, list_of(:integer))
  end
end
