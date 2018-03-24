defmodule MastaniServer.Factory do
  alias Helper.ORM
  alias MastaniServer.Repo
  alias MastaniServer.CMS
  alias MastaniServer.Accounts
  alias Helper.MastaniServer.Guardian

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
        mock(:community)
      ]
    }
  end

  defp mock_meta(:comment) do
    body = Faker.Lorem.sentence(%Range{first: 30, last: 80})

    %{
      body: body
    }
  end

  defp mock_meta(:author) do
    %{role: "normal", user: mock(:user)}
  end

  defp mock_meta(:community) do
    unique_num = System.unique_integer([:positive, :monotonic])
    name = Faker.Lorem.sentence(%Range{first: 3, last: 4})

    %{
      title: "community #{name} #{unique_num}",
      desc: "community desc",
      author: mock(:user)
    }
  end

  defp mock_meta(:tag) do
    unique_num = System.unique_integer([:positive, :monotonic])

    %{
      title: "#{Faker.Pizza.cheese()} #{unique_num}",
      type: "POST",
      # part mainly for CMS.create_tag usage
      part: "POST",
      color: "RED",
      # community: Faker.Pizza.topping(),
      community: mock(:community),
      user: mock(:user)
      # user_id: 1
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
      bio: Faker.Lorem.Shakespeare.romeo_and_juliet(),
      avatar_url: Faker.Avatar.image_url(),
      html_url: Faker.Avatar.image_url(),
      followers: unique_num * unique_num,
      following: unique_num * unique_num * unique_num
    }
  end

  def mock_attrs(_, attrs \\ %{})
  def mock_attrs(:user, attrs), do: mock_meta(:user) |> Map.merge(attrs)
  def mock_attrs(:post, attrs), do: mock_meta(:post) |> Map.merge(attrs)
  def mock_attrs(:community, attrs), do: mock_meta(:community) |> Map.merge(attrs)
  def mock_attrs(:tag, attrs), do: mock_meta(:tag) |> Map.merge(attrs)
  def mock_attrs(:github_profile, attrs), do: mock_meta(:github_profile) |> Map.merge(attrs)

  @doc """
  NOTICE: avoid Recursive problem
  bad example:
               mismatch                                       mismatch
                  |                                               |
      defp mock(:user), do: Accounts.User |> struct(mock_meta(:community))

  this line of code will cause SERIOUS Recursive problem
  """
  defp mock(:post), do: CMS.Post |> struct(mock_meta(:post))
  defp mock(:comment), do: CMS.Post |> struct(mock_meta(:comment))
  defp mock(:author), do: CMS.Author |> struct(mock_meta(:author))
  defp mock(:tag), do: CMS.Tag |> struct(mock_meta(:tag))
  defp mock(:user), do: Accounts.User |> struct(mock_meta(:user))
  defp mock(:community), do: CMS.Community |> struct(mock_meta(:community))

  def mock_jwt_token(clauses) do
    with {:ok, user} <- ORM.find_by(Accounts.User, clauses) do
      {:ok, token, _info} = Guardian.jwt_encode(user)

      "Bearer #{token}"
    end
  end

  defp mock(factory_name, attributes) do
    factory_name |> mock() |> struct(attributes)
  end

  @doc """
  # not use changeset because in test we may insert some attrs which not in schema
  # like: views, insert/update ... to test filter-sort,when ...
  """
  def db_insert(factory_name, attributes \\ []) do
    Repo.insert(mock(factory_name, attributes))
  end

  def db_insert_multi!(factory_name, count \\ 5) do
    for _u <- 1..count do
      db_insert(factory_name)
    end
  end
end
