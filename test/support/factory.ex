# ---
# create content
#
#
# ---

defmodule MastaniServer.Factory do
  alias MastaniServer.Repo
  alias MastaniServer.CMS
  alias MastaniServer.Accounts

  def mock(:post) do
    body = Faker.Lorem.sentence(%Range{first: 80, last: 120})

    %CMS.Post{
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

  def mock(:author) do
    %CMS.Author{role: "normal", user: mock(:user)}
  end

  def mock(:user) do
    unique_num = System.unique_integer([:positive, :monotonic])

    %Accounts.User{
      username: "#{Faker.Name.first_name()} #{unique_num}",
      nickname: Faker.Name.last_name(),
      bio: Faker.Lorem.Shakespeare.romeo_and_juliet(),
      company: Faker.Company.name()
    }
  end

  def mock(:community) do
    unique_num = System.unique_integer([:positive, :monotonic])

    %CMS.Community{
      title: "community #{unique_num}",
      desc: "community desc",
      author: mock(:user)
    }
  end

  def mock_attrs(_, attrs \\ %{})

  def mock_attrs(:user, attrs) do
    unique_num = System.unique_integer([:positive, :monotonic])

    %{
      username: "#{Faker.Name.first_name()} #{unique_num}",
      nickname: Faker.Name.last_name(),
      bio: Faker.Lorem.Shakespeare.romeo_and_juliet(),
      company: Faker.Company.name()
    }
    |> Map.merge(attrs)
  end

  def mock_attrs(:post, attrs) do
    unique_num = System.unique_integer([:positive, :monotonic])

    %{
      title: Faker.Lorem.Shakespeare.king_richard_iii(),
      body: Faker.Lorem.sentence(%Range{first: 80, last: 120}),
      digest: "fake digest",
      length: 100,
      community: "community #{unique_num}"
    }
    |> Map.merge(attrs)
  end

  def mock_attrs(:community, attrs) do
    unique_num = System.unique_integer([:positive, :monotonic])

    %{
      title: "community #{unique_num}",
      desc: "community desc",
      author: mock(:user)
    }
    |> Map.merge(attrs)
  end

  # ---
  def mock(factory_name, attributes) do
    # merge attributes as need
    factory_name |> mock() |> struct(attributes)
  end

  def db_insert(factory_name, attributes \\ []) do
    # not use changeset because in test we may insert some attrs which not in schema
    # like: views, insert/update ... to test filter-sort,when ...

    # User.changeset(%User{}, attrs)
    # |> Repo.insert!()
    Repo.insert(mock(factory_name, attributes))
  end

  # TODO:
  def db_insert_multi!(factory_name, count \\ 5) do
    for _u <- 1..count do
      db_insert(factory_name)
    end
  end
end
