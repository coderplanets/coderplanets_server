defmodule MastaniServerWeb.Resolvers.CMS do
  import ShortMaps
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]

  alias MastaniServer.{CMS, Accounts, Repo}
  alias Helper.ORM

  def post(_root, %{id: id}, _info), do: CMS.Post |> ORM.read(id, inc: :views)

  def posts(_root, ~m(filter)a, _info), do: CMS.Post |> ORM.find_all(filter)

  def community(_root, %{id: id}, _info), do: CMS.Community |> ORM.find(id)

  def communities(_root, ~m(filter)a, _info), do: CMS.Community |> ORM.find_all(filter)

  def community_posts_count(root, _args, _info) do
    "communities_posts"
    |> where([cp], cp.community_id == ^root.id)
    |> select([cp], count(cp.post_id))
    |> Repo.one()
    |> done
  end

  def create_community(_root, args, %{context: %{cur_user: user}}) do
    CMS.create_community(%{title: args.title, desc: args.desc, user_id: user.id})
  end

  def create_thread(_root, ~m(title)a, _info) do
    CMS.create_thread(~m(title)a)
  end

  def add_thread_to_community(_root, ~m(community_id thread_id)a, _info) do
    CMS.add_thread_to_community(~m(community_id thread_id)a)
  end

  def add_editor(_root, ~m(community_id user_id title)a, _) do
    CMS.add_editor(%Accounts.User{id: user_id}, %CMS.Community{id: community_id}, title)
  end

  def delete_editor(_root, ~m(community_id user_id)a, _) do
    CMS.delete_editor(%Accounts.User{id: user_id}, %CMS.Community{id: community_id})
  end

  def update_editor(_root, ~m(community_id user_id title)a, _) do
    CMS.update_editor(%Accounts.User{id: user_id}, %CMS.Community{id: community_id}, title)
  end

  # TODO
  # def create_tag(_root, args, %{context: %{cur_user: user}}) do
  def create_tag(_root, args, %{context: %{cur_user: user}}) do
    # args2 = for {k, v} <- args, into: %{}, do: {k, to_string(v)}
    # CMS.create_tag(args.part, args)
    CMS.create_tag(args.part, %{
      title: args.title,
      color: to_string(args.color),
      community: args.community,
      part: to_string(args.part),
      user_id: user.id
    })
  end

  # find_delete(CMS.Tag, id)
  def delete_tag(_root, %{id: id}, _info), do: CMS.Tag |> ORM.find_delete(id)

  def delete_community(_root, %{id: id}, _info), do: CMS.Community |> ORM.find_delete(id)

  def subscribe_community(_root, ~m(community_id)a, %{context: %{cur_user: cur_user}}) do
    CMS.subscribe_community(%Accounts.User{id: cur_user.id}, %CMS.Community{id: community_id})
  end

  def unsubscribe_community(_root, ~m(community_id)a, %{context: %{cur_user: cur_user}}) do
    CMS.unsubscribe_community(%Accounts.User{id: cur_user.id}, %CMS.Community{id: community_id})
  end

  def community_subscribers(_root, ~m(id filter)a, _info) do
    CMS.community_members(:subscribers, %CMS.Community{id: id}, filter)
  end

  def community_editors(_root, ~m(id filter)a, _info) do
    CMS.community_members(:editors, %CMS.Community{id: id}, filter)
  end

  def set_tag(_root, ~m(community part id tag_id)a, _info) do
    CMS.set_tag(community, part, id, tag_id)
  end

  def unset_tag(_root, ~m(id part tag_id)a, _info) do
    CMS.unset_tag(part, id, tag_id)
  end

  def set_community(_root, ~m(part id community)a, _info) do
    CMS.set_community(part, id, %CMS.Community{title: community})
  end

  def unset_community(_root, ~m(part id community)a, _info) do
    CMS.unset_community(part, id, %CMS.Community{title: community})
  end

  def get_tags(_root, ~m(community part)a, _info) do
    CMS.get_tags(community, to_string(part))
  end

  def create_post(_root, args, %{context: %{cur_user: user}}) do
    CMS.create_content(:post, %CMS.Author{user_id: user.id}, args)
  end

  def reaction(_root, ~m(id part action)a, %{context: %{cur_user: user}}) do
    CMS.reaction(part, action, id, user.id)
  end

  def undo_reaction(_root, ~m(id part action)a, %{context: %{cur_user: user}}) do
    CMS.undo_reaction(part, action, id, user.id)
  end

  def reaction_users(_root, ~m(id action part filter)a, _info) do
    CMS.reaction_users(part, action, id, filter)
  end

  def delete_post(_root, %{passport_source: content}, _info), do: ORM.delete(content)
  def delete_comment(_root, %{passport_source: content}, _info), do: ORM.delete(content)

  def update_post(_root, args, _info), do: ORM.update(args.passport_source, args)

  def create_comment(_root, ~m(part id body)a, %{context: %{cur_user: user}}) do
    CMS.create_comment(part, :comment, id, user.id, body)
  end
end
