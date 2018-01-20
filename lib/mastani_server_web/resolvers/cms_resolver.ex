defmodule MastaniServerWeb.Resolvers.CMS do
  alias MastaniServer.CMS
  alias MastaniServer.Utils.Helper

  # TODO: delete tag

  def load_author(root, _args, _info),
    do: CMS.load_author(%CMS.Author{id: root.author_id}) |> Helper.orm_resp()

  # def load_tags(root, _args, _info) do
  # CMS.contents(:post, :comment, root.id, first) |> Helper.orm_resp()
  # end

  def post(_root, %{id: id}, _info), do: CMS.one_conent(:post, :self, id) |> Helper.orm_resp()

  def posts(_root, %{filter: filter}, _info) do
    CMS.contents(:post, :self, filter) |> Helper.orm_resp()
  end

  def posts(_root, _args, _info) do
    default_filter = %{first: 10}
    CMS.contents(:post, :self, default_filter) |> Helper.orm_resp()
  end

  def create_community(_root, args, %{context: %{current_user: user}}) do
    CMS.create_community(%{title: args.title, desc: args.desc, user_id: user.id})
    |> Helper.orm_resp()
  end

  def create_tag(_root, args, %{context: %{current_user: user}}) do
    # args2 = for {k, v} <- args, into: %{}, do: {k, to_string(v)}

    CMS.create_tag(args.type, %{
      title: args.title,
      color: to_string(args.color),
      community: args.community,
      part: to_string(args.type),
      user_id: user.id
    })
    |> Helper.orm_resp()
  end

  def delete_community(_root, args, %{context: %{current_user: user}}) do
    CMS.delete_community(args.id)
  end

  def set_tag(_root, %{type: type, id: id, tag_id: tag_id}, %{context: %{current_user: user}}) do
    IO.inspect(user.id, label: "log this user to post history / system log")
    CMS.set_tag(type, id, tag_id) |> Helper.orm_resp()
  end

  def get_tags(_root, %{community: community, type: part}, _info) do
    CMS.get_tags(community, to_string(part))
  end

  def create_post(_root, args, %{context: %{current_user: user}}) do
    CMS.create_post(%CMS.Author{user_id: user.id}, args) |> Helper.orm_resp()
  end

  def create_post(_root, _args, _info), do: Helper.access_deny(:login)

  def reaction(_root, %{type: type, action: action, id: id}, %{context: %{current_user: user}}) do
    CMS.reaction(type, action, id, user.id) |> Helper.orm_resp()
  end

  def reaction(_root, _args, _info), do: Helper.access_deny(:login)

  def undo_reaction(_root, %{type: type, action: action, id: id}, %{
        context: %{current_user: user}
      }),
      do: CMS.undo_reaction(type, action, id, user.id) |> Helper.orm_resp()

  def undo_reaction(_root, _args, _info), do: Helper.access_deny(:login)

  def reaction_users(_root, %{type: type, id: id, filter: filter}, _info),
    do: CMS.reaction_users(type, :favorite, id, filter) |> Helper.orm_resp()

  def inline_reaction_users(root, %{type: type, action: action, filter: filter}, _info) do
    CMS.reaction_users(type, action, root.id, filter) |> Helper.orm_resp()
  end

  def inline_reaction_users(root, %{type: type, action: action}, _info) do
    default_filter = %{first: 3}
    CMS.reaction_users(type, action, root.id, default_filter) |> Helper.orm_resp()
  end

  def inline_reaction_users_count(root, %{type: type, action: action}, _info) do
    CMS.reaction_users_count(type, action, root.id) |> Helper.orm_resp()
  end

  # TODO delete should be root, one should be use invisible_post ..
  def delete_post(_root, %{post_id: id}, %{context: %{current_user: user}}) do
    CMS.delete_content(:post, :self, id, user) |> Helper.orm_resp()
  end

  def create_comment(_root, %{type: type, id: id, body: body}, %{context: %{current_user: user}}),
    do: CMS.create_comment(type, :comment, id, user.id, body) |> Helper.orm_resp()

  def create_comment(_root, _args, _info), do: Helper.access_deny(:login)

  def delete_comment(_root, %{type: type, id: id}, %{context: %{current_user: user}}) do
    CMS.delete_content(type, :comment, id, user) |> Helper.orm_resp()
  end

  def delete_comment(_root, _args, _info), do: Helper.access_deny(:login)
end
