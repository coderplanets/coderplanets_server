defmodule MastaniServerWeb.Resolvers.Accounts do
  import ShortMaps

  alias MastaniServer.Accounts
  alias MastaniServer.CMS
  alias Helper.{ORM, Certification}

  def user(_root, %{id: id}, _info), do: Accounts.User |> ORM.find(id)
  def users(_root, ~m(filter)a, _info), do: Accounts.User |> ORM.find_all(filter)

  def account(_root, _args, %{context: %{cur_user: cur_user}}),
    do: Accounts.User |> ORM.find(cur_user.id)

  def update_profile(_root, %{profile: profile}, %{context: %{cur_user: cur_user}}) do
    Accounts.update_profile(%Accounts.User{id: cur_user.id}, profile)
  end

  def github_signin(_root, %{github_user: github_user}, _info) do
    Accounts.github_signin(github_user)
  end

  # for user self's
  def subscribed_communities(_root, %{filter: filter}, %{cur_user: cur_user}) do
    Accounts.subscribed_communities(%Accounts.User{id: cur_user.id}, filter)
  end

  #
  def subscribed_communities(_root, %{user_id: "", filter: filter}, _info) do
    Accounts.default_subscribed_communities(filter)
  end

  # for check other users subscribed_communities
  def subscribed_communities(_root, %{user_id: user_id, filter: filter}, _info) do
    Accounts.subscribed_communities(%Accounts.User{id: user_id}, filter)
  end

  def subscribed_communities(_root, %{filter: filter}, _info) do
    Accounts.default_subscribed_communities(filter)
  end

  def get_passport(root, _args, %{context: %{cur_user: _}}) do
    CMS.get_passport(%Accounts.User{id: root.id})
  end

  def get_passport_string(root, _args, %{context: %{cur_user: _}}) do
    case CMS.get_passport(%Accounts.User{id: root.id}) do
      {:ok, passport} ->
        {:ok, Jason.encode!(passport)}

      {:error, _} ->
        {:ok, nil}
    end
  end

  def get_all_rules(_root, _args, %{context: %{cur_user: _}}) do
    cms_rules = Certification.all_rules(:cms, :stringify)

    {:ok,
     %{
       cms: cms_rules
     }}
  end

  # def create_user(_root, args, %{context: %{cur_user: %{root: true}}}) do
  # Accounts.create_user2(args)
  # end
end
