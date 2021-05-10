defmodule GroupherServerWeb.Schema.CMS.Types do
  @moduledoc """
  cms types used in queries & mutations
  """
  use Helper.GqlSchemaSuite

  import GroupherServerWeb.Schema.Helper.Fields
  import Ecto.Query, warn: false
  import Absinthe.Resolution.Helpers, only: [dataloader: 2, on_load: 2]

  alias GroupherServer.CMS
  alias GroupherServerWeb.Schema

  import_types(Schema.CMS.Misc)

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
    field(:id, :id)
    field(:title, :string)
    field(:digest, :string)
    field(:length, :integer)
    field(:link_addr, :string)
    field(:link_icon, :string)
    field(:copy_right, :string)
    field(:body, :string)
    field(:views, :integer)
    # NOTE: only meaningful in paged-xxx queries
    field(:is_pinned, :boolean)
    field(:trash, :boolean)
    field(:tags, list_of(:tag), resolve: dataloader(CMS, :tags))

    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:origial_community, :community, resolve: dataloader(CMS, :origial_community))
    field(:communities, list_of(:community), resolve: dataloader(CMS, :communities))

    field(:meta, :article_meta)
    field(:emotions, :article_emotions)

    field :comments, list_of(:comment) do
      arg(:filter, :members_filter)

      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :comments))
    end

    # comments_count
    # comments_participators / paged
    comments_counter_fields(:post)

    @desc "totalCount of unique participator list of a the comments"
    field :comments_participators_count, :integer do
      resolve(fn post, _args, %{context: %{loader: loader}} ->
        loader
        |> Dataloader.load(CMS, {:one, CMS.PostComment}, cp_count: post.id)
        |> on_load(fn loader ->
          {:ok, Dataloader.get(loader, CMS, {:one, CMS.PostComment}, cp_count: post.id)}
        end)
      end)
    end

    article_comments_fields()
    viewer_has_state_fields()
    # upvoted_count
    # collected_count

    timestamp_fields()
  end

  object :job do
    interface(:article)
    field(:id, :id)
    field(:title, :string)
    field(:desc, :string)
    field(:company, :string)
    field(:company_logo, :string)
    field(:company_link, :string)
    field(:digest, :string)
    field(:length, :integer)
    field(:link_addr, :string)
    field(:copy_right, :string)
    field(:body, :string)
    field(:views, :integer)

    field(:is_pinned, :boolean)
    field(:trash, :boolean)

    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:tags, list_of(:tag), resolve: dataloader(CMS, :tags))
    field(:origial_community, :community, resolve: dataloader(CMS, :origial_community))
    field(:communities, list_of(:community), resolve: dataloader(CMS, :communities))

    field(:meta, :article_meta)
    field(:emotions, :article_emotions)

    field(:salary, :string)
    field(:exp, :string)
    field(:education, :string)
    field(:field, :string)
    field(:finance, :string)
    field(:scale, :string)

    # comments_count
    # comments_participators
    article_comments_fields()
    viewer_has_state_fields()
    timestamp_fields()
  end

  object :repo do
    # interface(:article)
    field(:id, :id)
    field(:title, :string)
    field(:owner_name, :string)
    field(:owner_url, :string)
    field(:repo_url, :string)
    field(:author, :user, resolve: dataloader(CMS, :author))

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

    field(:views, :integer)
    field(:is_pinned, :boolean)
    field(:trash, :boolean)
    # TODO: remove
    # field(:trash, :boolean)

    field(:last_sync, :datetime)

    field(:tags, list_of(:tag), resolve: dataloader(CMS, :tags))
    field(:origial_community, :community, resolve: dataloader(CMS, :origial_community))
    field(:communities, list_of(:community), resolve: dataloader(CMS, :communities))

    viewer_has_state_fields()
    # comments_count
    # comments_participators

    timestamp_fields()
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

  object :thread do
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
    field(:threads, list_of(:thread), resolve: dataloader(CMS, :threads))
    field(:categories, list_of(:category), resolve: dataloader(CMS, :categories))

    @desc "total count of post contents"
    content_counts_field(:post, CMS.Post)

    @desc "total count of job contents"
    content_counts_field(:job, CMS.Job)

    @desc "total count of repo contents"
    content_counts_field(:repo, CMS.Repo)

    field :subscribers, list_of(:user) do
      arg(:filter, :members_filter)
      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :subscribers))
    end

    field :subscribers_count, :integer do
      arg(:count, :count_type, default_value: :count)
      arg(:type, :community_type, default_value: :community)
      resolve(dataloader(CMS, :subscribers))
      middleware(M.ConvertToInt)
    end

    field :viewer_has_subscribed, :boolean do
      arg(:viewer_did, :viewer_did_type, default_value: :viewer_did)

      middleware(M.Authorize, :login)
      middleware(M.PutCurrentUser)
      resolve(dataloader(CMS, :subscribers))
      middleware(M.ViewerDidConvert)
    end

    field :editors, list_of(:user) do
      arg(:filter, :members_filter)
      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :editors))
    end

    field :editors_count, :integer do
      arg(:count, :count_type, default_value: :count)
      arg(:type, :community_type, default_value: :community)
      resolve(dataloader(CMS, :editors))
      middleware(M.ConvertToInt)
    end

    field :threads_count, :integer do
      resolve(&R.CMS.threads_count/3)
    end

    field :tags_count, :integer do
      resolve(&R.CMS.tags_count/3)
    end

    field :contributes_digest, list_of(:integer) do
      # TODO add complex here to warning N+1 problem
      resolve(&R.Statistics.list_contributes_digest/3)
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

  object :tag do
    field(:id, :id)
    field(:title, :string)
    field(:color, :string)
    field(:thread, :string)
    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:community, :community, resolve: dataloader(CMS, :community))

    timestamp_fields()
  end

  object :article_comment_emotions do
    comment_emotion_fields()
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

  object :article_comment_reply do
    field(:id, :id)
    field(:body_html, :string)
    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:floor, :integer)
    field(:upvotes_count, :integer)
    field(:is_article_author, :boolean)
    field(:emotions, :article_comment_emotions)
    field(:meta, :article_comment_meta)
    field(:replies_count, :integer)
    field(:reply_to, :article_comment_reply)
    field(:viewer_has_upvoted, :boolean)

    timestamp_fields()
  end

  object :article_comment do
    field(:id, :id)
    field(:body_html, :string)
    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:is_pinned, :boolean)
    field(:floor, :integer)
    field(:upvotes_count, :integer)
    field(:emotions, :article_comment_emotions)
    field(:is_article_author, :boolean)
    field(:meta, :article_comment_meta)
    field(:reply_to, :article_comment_reply)
    field(:replies, list_of(:article_comment_reply))
    field(:replies_count, :integer)

    field(:is_deleted, :boolean)
    field(:viewer_has_upvoted, :boolean)

    timestamp_fields()
  end

  object :comment do
    comments_fields()
  end

  object :common_article do
    field(:thread, :string)
    field(:id, :id)
    # field(:body_html, :string)
    field(:title, :string)
    field(:author, :user, resolve: dataloader(CMS, :author))
  end

  object :post_comment do
    comments_fields()
    field(:post, :post, resolve: dataloader(CMS, :post))
  end

  object :repo_comment do
    comments_fields()
    field(:repo, :repo, resolve: dataloader(CMS, :repo))
  end

  object :paged_categories do
    field(:entries, list_of(:category))
    pagination_fields()
  end

  object :paged_posts do
    meta(:cache, max_age: 30)
    field(:entries, list_of(:post))
    pagination_fields()
  end

  object :paged_repos do
    field(:entries, list_of(:repo))
    pagination_fields()
  end

  object :paged_jobs do
    field(:entries, list_of(:job))
    pagination_fields()
  end

  object :paged_comments do
    field(:entries, list_of(:comment))
    pagination_fields()
  end

  object :paged_article_comments do
    field(:entries, list_of(:article_comment))
    pagination_fields()
  end

  object :paged_article_replies do
    field(:entries, list_of(:article_comment_reply))
    pagination_fields()
  end

  object :paged_post_comments do
    field(:entries, list_of(:post_comment))
    pagination_fields()
  end

  object :paged_communities do
    field(:entries, list_of(:community))
    pagination_fields()
  end

  object :paged_tags do
    field(:entries, list_of(:tag))
    pagination_fields()
  end

  object :paged_threads do
    field(:entries, list_of(:thread))
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
    # field(:isReported, :boolean)
    # field(:linked_posts_count, :integer)
    # field(:linked_jobs_count, :integer)
    # field(:linked_works_count, :integer)

    # reaction: %{
    #   rocketCount: 0,
    #   heartCount: 0,
    # }
  end
end
