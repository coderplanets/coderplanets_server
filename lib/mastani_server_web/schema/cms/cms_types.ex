defmodule MastaniServerWeb.Schema.CMS.Types do
  @moduledoc """
  cms types used in queries & mutations
  """
  use Helper.GqlSchemaSuite

  import MastaniServerWeb.Schema.Utils.Helper
  import Ecto.Query, warn: false
  import Absinthe.Resolution.Helpers, only: [dataloader: 2, on_load: 2]

  alias MastaniServer.CMS
  alias MastaniServerWeb.Schema

  import_types(Schema.CMS.Misc)

  object :idlike do
    field(:id, :id)
  end

  object :post do
    interface(:article)
    field(:id, :id)
    field(:title, :string)
    field(:digest, :string)
    field(:length, :integer)
    field(:link_addr, :string)
    field(:copy_right, :string)
    field(:body, :string)
    field(:views, :integer)
    # TODO: remove
    field(:pin, :boolean)
    field(:trash, :boolean)
    field(:tags, list_of(:tag), resolve: dataloader(CMS, :tags))

    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:communities, list_of(:community), resolve: dataloader(CMS, :communities))

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

    has_viewed_field()
    # fields for: favorite count, favorited_users, viewer_did_favorite..
    favorite_fields(:post)
    star_fields(:post)

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
    field(:location, :string)
    field(:length, :integer)
    field(:link_addr, :string)
    field(:body, :string)
    field(:views, :integer)

    field(:pin, :boolean)
    field(:trash, :boolean)

    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:tags, list_of(:tag), resolve: dataloader(CMS, :tags))
    field(:communities, list_of(:community), resolve: dataloader(CMS, :communities))

    field(:salary, :string)
    field(:exp, :string)
    field(:education, :string)
    field(:field, :string)

    # comments_count
    # comments_participators
    comments_counter_fields(:job)

    has_viewed_field()
    # fields for: favorite count, favorited_users, viewer_did_favorite..
    favorite_fields(:job)
    timestamp_fields()
  end

  object :video do
    interface(:article)
    field(:id, :id)
    field(:title, :string)
    field(:poster, :string)
    field(:thumbnil, :string)
    field(:desc, :string)
    field(:duration, :string)
    field(:author, :user, resolve: dataloader(CMS, :author))

    field(:source, :string)
    field(:publish_at, :string)
    field(:link, :string)
    field(:original_author, :string)
    field(:original_author_link, :string)
    field(:views, :integer)

    field(:pin, :boolean)
    field(:trash, :boolean)

    field(:tags, list_of(:tag), resolve: dataloader(CMS, :tags))
    field(:communities, list_of(:community), resolve: dataloader(CMS, :communities))

    # comments_count
    # comments_participators
    comments_counter_fields(:video)

    has_viewed_field()
    # fields for: favorite count, favorited_users, viewer_did_favorite..
    favorite_fields(:video)
    star_fields(:video)
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
    field(:pin, :boolean)
    field(:trash, :boolean)
    # TODO: remove
    # field(:pin, :boolean)
    # field(:trash, :boolean)

    field(:last_sync, :datetime)

    field(:tags, list_of(:tag), resolve: dataloader(CMS, :tags))
    field(:communities, list_of(:community), resolve: dataloader(CMS, :communities))

    has_viewed_field()
    # comments_count
    # comments_participators
    comments_counter_fields(:repo)
    # fields for: favorite count, favorited_users, viewer_did_favorite..
    favorite_fields(:repo)

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
    field(:date, :date)
    field(:count, :integer)
  end

  object :contribute_map do
    field(:start_date, :date)
    field(:end_date, :date)
    field(:total_count, :integer)
    field(:records, list_of(:contribute))
  end

  object :community do
    # meta(:cache, max_age: 30)
    field(:id, :id)
    field(:title, :string)
    field(:desc, :string)
    field(:raw, :string)
    field(:logo, :string)
    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:threads, list_of(:thread), resolve: dataloader(CMS, :threads))
    field(:categories, list_of(:category), resolve: dataloader(CMS, :categories))

    # Big thanks: https://elixirforum.com/t/grouping-error-in-absinthe-dadaloader/13671/2
    # see also: https://github.com/absinthe-graphql/dataloader/issues/25
    field :posts_count, :integer do
      resolve(fn community, _args, %{context: %{loader: loader}} ->
        loader
        |> Dataloader.load(CMS, {:one, CMS.Post}, posts_count: community.id)
        |> on_load(fn loader ->
          {:ok, Dataloader.get(loader, CMS, {:one, CMS.Post}, posts_count: community.id)}
        end)
      end)
    end

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

    field :contributes, list_of(:contribute) do
      # TODO add complex here to warning N+1 problem
      resolve(&R.Statistics.list_contributes/3)
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

  object :comment do
    comments_fields()
  end

  object :post_comment do
    comments_fields()
    field(:post, :post, resolve: dataloader(CMS, :post))
  end

  object :job_comment do
    comments_fields()
    field(:job, :job, resolve: dataloader(CMS, :job))
  end

  object :video_comment do
    comments_fields()
    field(:video, :video, resolve: dataloader(CMS, :video))
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
    field(:entries, list_of(:post))
    pagination_fields()
  end

  object :paged_videos do
    field(:entries, list_of(:video))
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

  object :paged_post_comments do
    field(:entries, list_of(:post_comment))
    pagination_fields()
  end

  object :paged_job_comments do
    field(:entries, list_of(:job_comment))
    pagination_fields()
  end

  object :paged_video_comments do
    field(:entries, list_of(:video_comment))
    pagination_fields()
  end

  object :paged_repo_comments do
    field(:entries, list_of(:repo_comment))
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
end
