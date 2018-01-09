defmodule MastaniServerWeb.Schema.CMS.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.Resolvers

  object :post do
    field(:id, non_null(:id))
    field(:title, non_null(:string))
    field(:body, non_null(:string))
    field(:author, :author, resolve: assoc(:author))
    # note the name convention here
    field(:starred_users, list_of(:user), resolve: assoc(:starredUsers))

    # TODO: isViewerfavorited
    field :favorites, list_of(:user) do
      resolve(&Resolvers.CMS.favorites_users/3)
    end

    # field(:starred_users, list_of(:user), resolve: assoc(:starredUsers))

    # field :starred_users, list_of(:user) do
    # resolve(
    # assoc(:starredUsers, fn posts_query, _args, _context ->
    # posts_query
    # |> IO.inspect(label: 'didi: ')
    # |> first
    # end)
    # )
    # end
    field(:comments, list_of(:comment), resolve: assoc(:comments))
  end

  object :author do
    field(:id, non_null(:id))
    field(:role, :string)
    field(:posts, list_of(:post), resolve: assoc(:posts))
  end

  object :comment do
    field(:id, non_null(:id))
    field(:body, :string)
  end
end
