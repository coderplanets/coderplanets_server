# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MastaniServer.Repo.insert!(%MastaniServer.SomeSchema{})
#

defmodule MastaniServer.MockUser do
  alias MastaniServer.Repo
  alias MastaniServer.Accounts.User

  def random_attrs do
    %{
      username: Faker.Name.first_name() <> " " <> Faker.Name.last_name(),
      nickname: Faker.Name.first_name() <> " " <> Faker.Name.last_name(),
      bio: Faker.Name.first_name(),
      company: Faker.Company.name()
    }
  end

  def random(count \\ 1) do
    for _u <- 1..count do
      insert_multi()
    end
  end

  def insert(user) do
    User.changeset(%User{}, user)
    |> Repo.insert!()
  end

  defp insert_multi do
    User.changeset(%User{}, random_attrs())
    |> Repo.insert!()
  end
end
