# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :groupher_server, ecto_repos: [GroupherServer.Repo]

# Configures the endpoint
config :groupher_server, GroupherServerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Ru3N3sehqeuFjBV2Z6k7FuyA59fH8bWm8D4aZWu2RifP3xKMBYo3YRILrnXAGezM",
  render_errors: [view: GroupherServerWeb.ErrorView, accepts: ~w(json)],
  pubsub_server: GroupherServer.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :groupher_server, :mix_test_watch,
  exclude: [~r/docs\/.*/, ~r/deps\/.*/, ~r/mix.exs/],
  clear: true

config :pre_commit, commands: ["format"], verbose: false
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.

config :groupher_server, :general,
  site_host: "https://groupher.com",
  page_size: 30,
  inner_page_size: 5,
  # today is not include
  community_contribute_days: 30,
  user_contribute_months: 6,
  default_subscribed_communities: 20,
  publish_throttle_interval_minutes: 3,
  publish_throttle_hour_limit: 20,
  publish_throttle_day_limit: 30,
  # membership
  senior_amount_threshold: 51.2,
  # user achievements
  user_achieve_upvote_weight: 1,
  user_achieve_watch_weight: 1,
  user_achieve_collect_weight: 2,
  user_achieve_follow_weight: 3,
  # others
  # 在这个时间段内，多条提醒消息将被合并为一条
  notify_group_interval_hour: 1,
  nofity_actions: [:upvote, :comment, :reply, :collect, :follow]

config :groupher_server, :customization,
  theme: "cyan",
  community_chart: false,
  brainwash_free: false,
  banner_layout: "digest",
  contents_layout: "digest",
  content_divider: false,
  content_hover: true,
  mark_viewed: true,
  display_density: "20",
  sidebar_communities_index: %{}

config :groupher_server, :article,
  min_length: 10,
  max_length: 20_000,
  # NOTE: do not change unless you know what you are doing
  threads: [:post, :job, :repo, :blog, :works, :radar, :guide, :meetup, :drink],
  # in this period, paged articles will sort front if non-article-author commented
  # 在此时间段内，一旦有非文章作者的用户评论，该文章就会排到前面
  active_period_days: %{
    default: 10
    # post: 10,
    # job: 10,
    # ...
  },
  # record count in article meta
  # works use 8
  max_upvoted_users_count: 8,

  # NOTE: if you want to add/remove emotion, just edit the list below
  # and migrate the field to table "articles_users_emotions"
  emotions: [
    :upvote,
    :downvote,
    :beer,
    :heart,
    :biceps,
    :orz,
    :confused,
    :pill,
    :popcorn
  ],
  # NOTE: if you want to add/remove emotion, just edit the list below
  # and migrate the field to table "articles_comments_users_emotions"
  comment_emotions: [
    :downvote,
    :beer,
    :heart,
    :biceps,
    :orz,
    :confused,
    :pill,
    :popcorn
  ],
  digest_length: 150,
  archive_threshold: %{
    # for post, blog, job, works, radar, job
    default: [weeks: -1],
    meetups: [months: -1],
    drink: [years: -99],
    repo: [years: -99],
    guide: [years: -99]
  }

config :groupher_server, GroupherServerWeb.Gettext, default_locale: "zh_CN", locales: ~w(en zh_CN)

config :groupher_server, :cloud_assets,
  static_icon: "https://cps-oss.oss-cn-shanghai.aliyuncs.com/icons/static"

#  config email services
config :groupher_server, :system_emails,
  support_email: "coderplanets <support@group.coderplanets.com>",
  admin_email: "mydearxym@qq.com",
  welcome_new_register: true,
  notify_admin_on_new_user: true,
  notify_admin_on_content_created: true

config :groupher_server, GroupherServer.Mailer,
  adapter: Bamboo.MailgunAdapter,
  domain: "mailer.coderplanets.com"

config :groupher_server, :cache,
  pool: %{
    common: %{
      name: :common,
      size: 5000,
      seconds: 10 * 60
    },
    user_login: %{
      name: :user_login,
      size: 10_000,
      seconds: 10_080 * 60
    },
    blog_rss: %{
      name: :blog_rss,
      size: 1000,
      seconds: 15 * 60
    },
    online_status: %{
      name: :online_status,
      size: 30,
      seconds: 25
    }
  }

# cron-like job scheduler
config :groupher_server, Helper.Scheduler,
  jobs: [
    # Every midnight
    {"@daily", {Helper.Scheduler, :clear_all_cache, []}},
    {"@daily", {Helper.Scheduler, :archive_artiments, []}},
    # Every 59 minutes
    {"*/59 * * * *", {Helper.Scheduler, :articles_audition, []}},
    # Every 29 minutes
    {"*/29 * * * *", {Helper.Scheduler, :comments_audition, []}},
    online_status: [
      # Runs every 20 seconds
      schedule: {:extended, "*/20"},
      task: {Helper.Scheduler, :gather_online_status, []}
    ]
  ]

config :tesla, adapter: Tesla.Adapter.Hackney

# handle background jobs
config :rihanna,
  jobs_table_name: "background_jobs",
  producer_postgres_connection: {Ecto, GroupherServer.Repo}

import_config "#{Mix.env()}.exs"

if File.exists?("config/#{Mix.env()}.secret.exs") do
  import_config "#{Mix.env()}.secret.exs"
end
