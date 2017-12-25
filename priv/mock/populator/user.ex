# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MastaniServer.Repo.insert!(%MastaniServer.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias MastaniServer.Accounts.User
alias MastaniServer.Repo

defmodule MastaniServer.Mock.User do
  alias MastaniServer.Repo

  def user_attrs do
    %{
      username: Faker.Name.first_name() <> " " <> Faker.Name.last_name(),
      nickname: Faker.Name.first_name() <> " " <> Faker.Name.last_name(),
      bio: Faker.Name.first_name(),
      company: Faker.Company.name()
    }
  end

  def random(count \\ 1) do
    for _u <- 1..count do
      insert_mock_user()
    end
  end

  def insert(user) do
    User.changeset(%User{}, user)
    |> Repo.insert!
  end

  defp insert_mock_user do
    User.changeset(%User{}, user_attrs())
    |> Repo.insert!()
  end
end
