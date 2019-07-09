defmodule GroupherServer.Support.Factory do
  @moduledoc """
  This module defines the mock data/func to be used by
  tests that require insert some mock data to db.

  for example you can db_insert(:user) to insert user into db
  """
  import Helper.Utils, only: [done: 1]

  alias GroupherServer.Repo
  alias GroupherServer.{Accounts, CMS, Delivery}

  defp mock_meta(:post) do
    body = Faker.Lorem.sentence(%Range{first: 80, last: 120})

    %{
      title: String.slice(body, 1, 49),
      body: body,
      digest: String.slice(body, 1, 150),
      length: String.length(body),
      author: mock(:author),
      views: Enum.random(0..2000),
      communities: [
        mock(:community),
        mock(:community)
      ]
    }
  end

  defp mock_meta(:video) do
    desc = Faker.Lorem.sentence(%Range{first: 15, last: 60})
    source_enum = ["youtube", "bilibil", "vimeo", "other"]

    %{
      title: String.slice(desc, 1, 49),
      poster: Faker.Avatar.image_url(),
      thumbnil: Faker.Avatar.image_url(),
      desc: String.slice(desc, 1, 49),
      duration: "03:30",
      duration_sec: Enum.random(300..12_000),
      source: source_enum |> Enum.at(Enum.random(0..(length(source_enum) - 1))),
      link: "http://www.youtube.com/video/1",
      original_author: "mydearxym",
      original_author_link: "http://www.youtube.com/user/1",
      author: mock(:author),
      views: Enum.random(0..2000),
      publish_at: Timex.today() |> Timex.to_datetime(),
      communities: [
        mock(:community),
        mock(:community)
      ]
    }
  end

  defp mock_meta(:repo) do
    desc = Faker.Lorem.sentence(%Range{first: 15, last: 60})

    %{
      title: String.slice(desc, 1, 49),
      owner_name: "coderplanets",
      owner_url: "http://www.github.com/coderplanets",
      repo_url: "http://www.github.com/coderplanets//coderplanets_server",
      desc: desc,
      homepage_url: "http://www.github.com/coderplanets",
      readme: desc,
      issues_count: Enum.random(0..2000),
      prs_count: Enum.random(0..2000),
      fork_count: Enum.random(0..2000),
      star_count: Enum.random(0..2000),
      watch_count: Enum.random(0..2000),
      license: "MIT",
      release_tag: "v22",
      primary_language: %{
        name: "javascript",
        color: "tomato"
      },
      contributors: [
        mock_meta(:repo_contributor),
        mock_meta(:repo_contributor)
      ],
      author: mock(:author),
      views: Enum.random(0..2000),
      communities: [
        mock(:community),
        mock(:community)
      ]
    }
  end

  defp mock_meta(:wiki) do
    %{
      community: mock(:community),
      readme: Faker.Lorem.sentence(%Range{first: 15, last: 60}),
      last_sync: Timex.today() |> Timex.to_datetime(),
      contributors: [
        mock_meta(:github_contributor),
        mock_meta(:github_contributor),
        mock_meta(:github_contributor)
      ]
    }
  end

  defp mock_meta(:cheatsheet) do
    mock_meta(:wiki)
  end

  defp mock_meta(:github_contributor) do
    unique_num = System.unique_integer([:positive, :monotonic])

    %{
      github_id: "#{unique_num}-#{Faker.Lorem.sentence(%Range{first: 5, last: 10})}",
      avatar: Faker.Avatar.image_url(),
      html_url: Faker.Avatar.image_url(),
      nickname: "mydearxym2",
      bio: Faker.Lorem.sentence(%Range{first: 15, last: 60}),
      location: "location #{unique_num}",
      company: Faker.Company.name()
    }
  end

  defp mock_meta(:job) do
    body = Faker.Lorem.sentence(%Range{first: 80, last: 120})

    salary_enum = ["2k以下", "2k-5k", "5k-10k", "10k-15k", "15k-25k", "20k-50k", "50k以上"]
    exp_enum = ["不限", "应届", "3年以下", "3-5年", "5-10年", "10年以上"]
    education_enum = ["不限", "大专", "本科", "硕士", "博士"]
    field_enum = ["互联网", "电子商务", "金融", "企业服务", "教育", "游戏", "O2O", "区块链"]
    finance_enum = ["未融资", "天使轮", "A轮", "B轮", "C轮", "D轮以上", "已上市", "不需融资"]
    scale_enum = ["少于15人", "15-50人", "50-150人", "150-500人", "500-2000人", "2000人以上"]

    %{
      title: String.slice(body, 1, 49),
      company: Faker.Company.name(),
      company_logo: Faker.Avatar.image_url(),
      body: body,
      desc: "活少, 美女多",
      digest: String.slice(body, 1, 150),
      length: String.length(body),
      author: mock(:author),
      views: Enum.random(0..2000),
      salary: salary_enum |> Enum.at(Enum.random(0..(length(salary_enum) - 1))),
      exp: exp_enum |> Enum.at(Enum.random(0..(length(exp_enum) - 1))),
      education: education_enum |> Enum.at(Enum.random(0..(length(education_enum) - 1))),
      field: field_enum |> Enum.at(Enum.random(0..(length(field_enum) - 1))),
      finance: finance_enum |> Enum.at(Enum.random(0..(length(finance_enum) - 1))),
      scale: scale_enum |> Enum.at(Enum.random(0..(length(scale_enum) - 1))),
      communities: [
        mock(:community)
      ]
    }
  end

  defp mock_meta(:comment) do
    body = Faker.Lorem.sentence(%Range{first: 30, last: 80})

    %{body: body}
  end

  defp mock_meta(:mention) do
    unique_num = System.unique_integer([:positive, :monotonic])

    %{
      from_user: mock(:user),
      to_user: mock(:user),
      source_id: "1",
      source_type: "post",
      source_preview: "source_preview #{unique_num}."
    }
  end

  defp mock_meta(:author) do
    %{role: "normal", user: mock(:user)}
  end

  defp mock_meta(:communities_threads) do
    %{community_id: 1, thread_id: 1}
  end

  defp mock_meta(:thread) do
    unique_num = System.unique_integer([:positive, :monotonic])
    %{title: "thread #{unique_num}", raw: "thread #{unique_num}", index: :rand.uniform(20)}
  end

  defp mock_meta(:community) do
    unique_num = System.unique_integer([:positive, :monotonic])
    random_num = Enum.random(0..2000)

    title = "community_#{random_num}_#{unique_num}"

    %{
      title: title,
      aka: title,
      desc: "community desc",
      raw: title,
      logo: "https://coderplanets.oss-cn-beijing.aliyuncs.com/icons/pl/elixir.svg",
      author: mock(:user)
    }
  end

  defp mock_meta(:category) do
    unique_num = System.unique_integer([:positive, :monotonic])

    %{
      title: "category#{unique_num}",
      raw: "category#{unique_num}",
      author: mock(:author)
    }
  end

  defp mock_meta(:tag) do
    unique_num = System.unique_integer([:positive, :monotonic])

    %{
      title: "#{Faker.Pizza.cheese()} #{unique_num}",
      thread: "POST",
      color: "YELLOW",
      # community: Faker.Pizza.topping(),
      community: mock(:community),
      author: mock(:author)
      # user_id: 1
    }
  end

  defp mock_meta(:sys_notification) do
    unique_num = System.unique_integer([:positive, :monotonic])

    %{
      source_id: "#{unique_num}",
      source_title: "#{Faker.Pizza.cheese()}",
      source_type: "post",
      source_preview: "#{Faker.Pizza.cheese()}"
    }
  end

  defp mock_meta(:user) do
    unique_num = System.unique_integer([:positive, :monotonic])

    %{
      # username: "#{Faker.Name.first_name()} #{unique_num}",
      login: "#{Faker.Name.first_name()}#{unique_num}" |> String.downcase(),
      nickname: "#{Faker.Name.first_name()}#{unique_num}",
      bio: Faker.Lorem.Shakespeare.romeo_and_juliet(),
      avatar: Faker.Avatar.image_url(),
      email: "faker@gmail.com"
    }
  end

  defp mock_meta(:repo_contributor) do
    %{
      avatar: Faker.Avatar.image_url(),
      html_url: Faker.Avatar.image_url(),
      nickname: "mydearxym2"
    }
  end

  defp mock_meta(:github_profile) do
    unique_num = System.unique_integer([:positive, :monotonic])

    %{
      id: "#{Faker.Name.first_name()} #{unique_num}",
      login: "#{Faker.Name.first_name()}#{unique_num}",
      github_id: "#{unique_num + 1000}",
      node_id: "#{unique_num + 2000}",
      access_token: "#{unique_num + 3000}",
      bio: Faker.Lorem.Shakespeare.romeo_and_juliet(),
      company: Faker.Company.name(),
      location: "chengdu",
      email: Faker.Internet.email(),
      avatar_url: Faker.Avatar.image_url(),
      html_url: Faker.Avatar.image_url(),
      followers: unique_num * unique_num,
      following: unique_num * unique_num * unique_num
    }
  end

  defp mock_meta(:bill) do
    %{
      payment_usage: "donate",
      payment_method: "alipay",
      amount: 51.2,
      note: "thank you"
    }
  end

  def mock_attrs(_, attrs \\ %{})
  def mock_attrs(:user, attrs), do: mock_meta(:user) |> Map.merge(attrs)
  def mock_attrs(:author, attrs), do: mock_meta(:author) |> Map.merge(attrs)
  def mock_attrs(:post, attrs), do: mock_meta(:post) |> Map.merge(attrs)
  def mock_attrs(:video, attrs), do: mock_meta(:video) |> Map.merge(attrs)
  def mock_attrs(:repo, attrs), do: mock_meta(:repo) |> Map.merge(attrs)
  def mock_attrs(:job, attrs), do: mock_meta(:job) |> Map.merge(attrs)
  def mock_attrs(:community, attrs), do: mock_meta(:community) |> Map.merge(attrs)
  def mock_attrs(:thread, attrs), do: mock_meta(:thread) |> Map.merge(attrs)
  def mock_attrs(:mention, attrs), do: mock_meta(:mention) |> Map.merge(attrs)

  def mock_attrs(:wiki, attrs), do: mock_meta(:wiki) |> Map.merge(attrs)
  def mock_attrs(:cheatsheet, attrs), do: mock_meta(:cheatsheet) |> Map.merge(attrs)

  def mock_attrs(:github_contributor, attrs),
    do: mock_meta(:github_contributor) |> Map.merge(attrs)

  def mock_attrs(:communities_threads, attrs),
    do: mock_meta(:communities_threads) |> Map.merge(attrs)

  def mock_attrs(:tag, attrs), do: mock_meta(:tag) |> Map.merge(attrs)
  def mock_attrs(:sys_notification, attrs), do: mock_meta(:sys_notification) |> Map.merge(attrs)
  def mock_attrs(:category, attrs), do: mock_meta(:category) |> Map.merge(attrs)
  def mock_attrs(:github_profile, attrs), do: mock_meta(:github_profile) |> Map.merge(attrs)

  def mock_attrs(:bill, attrs), do: mock_meta(:bill) |> Map.merge(attrs)

  # NOTICE: avoid Recursive problem
  # bad example:
  # mismatch                                       mismatch
  # |                                               |
  # defp mock(:user), do: Accounts.User |> struct(mock_meta(:community))

  # this line of code will cause SERIOUS Recursive problem

  defp mock(:post), do: CMS.Post |> struct(mock_meta(:post))
  defp mock(:video), do: CMS.Video |> struct(mock_meta(:video))
  defp mock(:repo), do: CMS.Repo |> struct(mock_meta(:repo))
  defp mock(:job), do: CMS.Job |> struct(mock_meta(:job))
  defp mock(:wiki), do: CMS.CommunityWiki |> struct(mock_meta(:wiki))
  defp mock(:cheatsheet), do: CMS.CommunityCheatsheet |> struct(mock_meta(:cheatsheet))
  defp mock(:comment), do: CMS.Comment |> struct(mock_meta(:comment))
  defp mock(:mention), do: Delivery.Mention |> struct(mock_meta(:mention))
  defp mock(:author), do: CMS.Author |> struct(mock_meta(:author))
  defp mock(:category), do: CMS.Category |> struct(mock_meta(:category))
  defp mock(:tag), do: CMS.Tag |> struct(mock_meta(:tag))

  defp mock(:sys_notification),
    do: Delivery.SysNotification |> struct(mock_meta(:sys_notification))

  defp mock(:user), do: Accounts.User |> struct(mock_meta(:user))
  defp mock(:community), do: CMS.Community |> struct(mock_meta(:community))
  defp mock(:thread), do: CMS.Thread |> struct(mock_meta(:thread))

  defp mock(:communities_threads),
    do: CMS.CommunityThread |> struct(mock_meta(:communities_threads))

  defp mock(factory_name, attributes) do
    factory_name |> mock() |> struct(attributes)
  end

  # """
  # not use changeset because in test we may insert some attrs which not in schema
  # like: views, insert/update ... to test filter-sort,when ...
  # """
  def db_insert(factory_name, attributes \\ []) do
    Repo.insert(mock(factory_name, attributes))
  end

  def db_insert_multi(factory_name, count \\ 2) do
    results =
      Enum.reduce(1..count, [], fn _, acc ->
        {:ok, value} = db_insert(factory_name)
        acc ++ [value]
      end)

    results |> done
  end

  alias GroupherServer.Accounts.User

  def mock_sys_notification(count \\ 3) do
    # {:ok, sys_notifications} = db_insert_multi(:sys_notification, count)
    db_insert_multi(:sys_notification, count)
  end

  def mock_mentions_for(%User{id: _to_user_id} = user, count \\ 3) do
    {:ok, users} = db_insert_multi(:user, count)

    Enum.map(users, fn u ->
      unique_num = System.unique_integer([:positive, :monotonic])

      info = %{
        community: "elixir",
        source_id: "1",
        source_title: "Title #{unique_num}",
        source_type: "post",
        source_preview: "preview #{unique_num}"
      }

      {:ok, _} = Delivery.mention_others(u, [%{id: user.id}], info)
    end)
  end

  def mock_notifications_for(%User{id: _to_user_id} = user, count \\ 3) do
    {:ok, users} = db_insert_multi(:user, count)

    Enum.map(users, fn u ->
      unique_num = System.unique_integer([:positive, :monotonic])

      info = %{
        source_id: "1",
        source_title: "Title #{unique_num}",
        source_type: "post",
        source_preview: "preview #{unique_num}",
        action: "like"
      }

      {:ok, _} = Delivery.notify_someone(u, user, info)
    end)
  end
end
