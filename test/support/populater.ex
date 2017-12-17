
alias MastaniServer.Accounts.User
alias MastaniServer.Repo

defmodule MastaniServer.Populater do

  alias MastaniServer.Repo

  def user_attrs do
    %{
      username: Faker.Name.first_name() <> " " <> Faker.Name.last_name(),
      nickname: Faker.Name.first_name() <> " " <> Faker.Name.last_name(),
      bio: Faker.Name.first_name(),
      company: Faker.Company.name()
    }
  end

  def mock_user(count \\ 1) do
    for _u <- 1..count do
      insert_user()
    end
  end

  defp insert_user do
    User.changeset(%User{}, user_attrs())
    |> Repo.insert!()
  end
end

# MastaniServer.Populater.mock_user(10)
