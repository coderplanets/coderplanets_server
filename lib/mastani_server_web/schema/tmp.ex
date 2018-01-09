defmodule MastaniServerWeb.Schema.CMS.Tmp do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.Resolvers

  # book 05-mutations-start, also :date, enum , interface reduce-query example
  # Enum.reduce 的例子参见 03-userinput 4-ordering menu.ex, 很酷

  # union 的例子参见 04-flexibility 2-unions
  @desc "Filtering options for the menu item list"
  input_object :menu_item_filter do
    @desc "Matching a name"
    field(:name, :string)

    @desc "Matching a category name"
    field(:category, :string)

    @desc "Matching a tag"
    field(:tag, :string)

    @desc "Priced above a value"
    field(:priced_above, :float)

    @desc "Priced below a value"
    field(:priced_below, :float)
  end

  # querys
  object :cms_queries do
    @desc "hehehef: Get all links"
    field :all_posts, non_null(list_of(non_null(:post))) do
      arg(:filter, :menu_item_filter)
      resolve(&Resolvers.CMS.all_posts/3)
    end
  end
end
