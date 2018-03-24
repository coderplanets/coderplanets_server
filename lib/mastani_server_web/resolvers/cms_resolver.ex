defmodule MastaniServerWeb.Resolvers.CMS do
  alias MastaniServer.CMS
  alias Helper.ORM

  def post(_root, %{id: id}, _info), do: CMS.Post |> ORM.read(id, inc: :views)

  def posts(_root, %{filter: filter}, _info), do: CMS.Post |> ORM.read_all(filter)

  def create_community(_root, args, %{context: %{current_user: user}}) do
    CMS.create_community(%{title: args.title, desc: args.desc, user_id: user.id})
  end

  # TODO
  def create_tag(_root, args, %{context: %{current_user: user}}) do
    # args2 = for {k, v} <- args, into: %{}, do: {k, to_string(v)}
    CMS.create_tag(args.type, %{
      title: args.title,
      color: to_string(args.color),
      community: args.community,
      part: to_string(args.type),
      user_id: user.id
    })
  end

  # find_delete(CMS.Tag, id)
  def delete_tag(_root, %{id: id}, _info), do: CMS.Tag |> ORM.find_delete(id)

  def delete_community(_root, %{id: id}, _info), do: CMS.Community |> ORM.find_delete(id)

  def set_tag(_root, %{type: type, id: id, tag_id: tag_id}, _info) do
    CMS.set_tag(type, id, tag_id)
  end

  def unset_tag(_root, %{type: type, id: id, tag_id: tag_id}, _info) do
    CMS.unset_tag(type, id, tag_id)
  end

  def set_community(_root, %{type: type, id: id, community_id: community_id}, _info) do
    CMS.set_community(type, id, community_id)
  end

  def unset_community(_root, %{type: type, id: id, community_id: community_id}, _info) do
    CMS.unset_community(type, id, community_id)
  end

  def get_tags(_root, %{community: community, type: part}, _info) do
    CMS.get_tags(community, to_string(part))
  end

  def create_post(_root, args, %{context: %{current_user: user}}) do
    # args.community = "elxiir"
    CMS.create_content(:post, %CMS.Author{user_id: user.id}, args)
  end

  def reaction(_root, %{type: type, action: action, id: id}, %{context: %{current_user: user}}) do
    CMS.reaction(type, action, id, user.id)
  end

  def undo_reaction(_root, %{type: type, action: action, id: id}, %{
        context: %{current_user: user}
      }),
      do: CMS.undo_reaction(type, action, id, user.id)

  def reaction_users(_root, %{id: id, action: action, type: type, filter: filter}, _info) do
    CMS.reaction_users(type, action, id, filter)
  end

  def reaction_count(root, %{type: type, action: action}, _info) do
    CMS.reaction_count(type, action, root.id)
  end

  def viewer_has_reacted(root, %{type: type, action: action}, %{context: %{current_user: user}}) do
    CMS.viewer_has_reacted(type, action, root.id, user.id)
  end

  def delete_post(_root, %{content_tobe_operate: content}, _info), do: ORM.delete(content)
  def delete_comment(_root, %{content_tobe_operate: content}, _info), do: ORM.delete(content)

  def update_post(_root, args, _info), do: ORM.update(args.content_tobe_operate, args)

  def create_comment(_root, %{type: type, id: id, body: body}, %{context: %{current_user: user}}),
    do: CMS.create_comment(type, :comment, id, user.id, body)
end
