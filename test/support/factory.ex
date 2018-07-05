defmodule MastaniServer.Factory do
  # alias Helper.ORM

  import Helper.Utils, only: [done: 1]

  alias MastaniServer.Repo
  alias MastaniServer.{CMS, Accounts, Delivery}

  defp mock_meta(:post) do
    body = Faker.Lorem.sentence(%Range{first: 80, last: 120})

    %{
      title: Faker.Lorem.Shakespeare.king_richard_iii(),
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

  defp mock_meta(:job) do
    body = Faker.Lorem.sentence(%Range{first: 80, last: 120})
    unique_num = System.unique_integer([:positive, :monotonic])

    %{
      title: Faker.Lorem.Shakespeare.king_richard_iii(),
      company: Faker.Company.name(),
      company_logo: Faker.Avatar.image_url(),
      location: "location #{unique_num}",
      body: body,
      digest: String.slice(body, 1, 150),
      length: String.length(body),
      author: mock(:author),
      views: Enum.random(0..2000),
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
    # name = Faker.Lorem.sentence(%Range{first: 3, last: 4})

    %{
      title: "community_#{unique_num}",
      desc: "community desc",
      raw: "community_#{unique_num}",
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
      nickname: "#{Faker.Name.first_name()} #{unique_num}",
      bio: Faker.Lorem.Shakespeare.romeo_and_juliet(),
      avatar: Faker.Avatar.image_url()
    }
  end

  defp mock_meta(:github_profile) do
    unique_num = System.unique_integer([:positive, :monotonic])

    %{
      id: "#{Faker.Name.first_name()} #{unique_num}",
      login: "#{Faker.Name.first_name()} #{unique_num}",
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

  def mock_attrs(_, attrs \\ %{})
  def mock_attrs(:user, attrs), do: mock_meta(:user) |> Map.merge(attrs)
  def mock_attrs(:author, attrs), do: mock_meta(:author) |> Map.merge(attrs)
  def mock_attrs(:post, attrs), do: mock_meta(:post) |> Map.merge(attrs)
  def mock_attrs(:job, attrs), do: mock_meta(:job) |> Map.merge(attrs)
  def mock_attrs(:community, attrs), do: mock_meta(:community) |> Map.merge(attrs)
  def mock_attrs(:thread, attrs), do: mock_meta(:thread) |> Map.merge(attrs)
  def mock_attrs(:mention, attrs), do: mock_meta(:mention) |> Map.merge(attrs)

  def mock_attrs(:communities_threads, attrs),
    do: mock_meta(:communities_threads) |> Map.merge(attrs)

  def mock_attrs(:tag, attrs), do: mock_meta(:tag) |> Map.merge(attrs)
  def mock_attrs(:sys_notification, attrs), do: mock_meta(:sys_notification) |> Map.merge(attrs)
  def mock_attrs(:category, attrs), do: mock_meta(:category) |> Map.merge(attrs)
  def mock_attrs(:github_profile, attrs), do: mock_meta(:github_profile) |> Map.merge(attrs)

  # NOTICE: avoid Recursive problem
  # bad example:
  # mismatch                                       mismatch
  # |                                               |
  # defp mock(:user), do: Accounts.User |> struct(mock_meta(:community))

  # this line of code will cause SERIOUS Recursive problem

  defp mock(:post), do: CMS.Post |> struct(mock_meta(:post))
  defp mock(:job), do: CMS.Job |> struct(mock_meta(:job))
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
    Enum.reduce(1..count, [], fn _, acc ->
      {:ok, value} = db_insert(factory_name)
      acc ++ [value]
    end)
    |> done
  end

  alias MastaniServer.Accounts.User

  def mock_sys_notification(count \\ 3) do
    # {:ok, sys_notifications} = db_insert_multi(:sys_notification, count)
    db_insert_multi(:sys_notification, count)
  end

  def mock_mentions_for(%User{id: _to_user_id} = user, count \\ 3) do
    {:ok, users} = db_insert_multi(:user, count)

    Enum.map(users, fn u ->
      unique_num = System.unique_integer([:positive, :monotonic])

      info = %{
        source_id: "1",
        source_title: "Title #{unique_num}",
        source_type: "post",
        source_preview: "preview #{unique_num}"
      }

      {:ok, _} = Delivery.mention_someone(u, user, info)
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
