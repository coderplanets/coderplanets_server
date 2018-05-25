defmodule MastaniServerWeb.Resolvers.CMS do
  @moduledoc false

  import ShortMaps
  import Ecto.Query, warn: false

  alias MastaniServer.{CMS, Accounts}
  alias MastaniServer.CMS.{Post, Job, Community, Category, Tag}
  alias Helper.ORM

  # #######################
  # community ..
  # #######################
  def community(_root, %{id: id}, _info), do: Community |> ORM.find(id)
  def community(_root, %{title: title}, _info), do: Community |> ORM.find_by(title: title)
  def community(_root, _args, _info), do: {:error, "please provide community id or title"}
  def paged_communities(_root, ~m(filter)a, _info), do: Community |> ORM.find_all(filter)

  def create_community(_root, args, %{context: %{cur_user: user}}) do
    args = args |> Map.merge(%{user_id: user.id})
    Community |> ORM.create(args)
  end

  def update_community(_root, args, _info), do: Community |> ORM.find_update(args)

  def delete_community(_root, %{id: id}, _info), do: Community |> ORM.find_delete(id)

  # #######################
  # community part (post, job)
  # #######################
  def post(_root, %{id: id}, _info), do: Post |> ORM.read(id, inc: :views)
  def paged_posts(_root, ~m(filter)a, _info), do: Post |> ORM.find_all(filter)

  def job(_root, %{id: id}, _info), do: Job |> ORM.read(id, inc: :views)
  def paged_jobs(_root, ~m(filter)a, _info), do: Job |> ORM.find_all(filter)

  def create_content(_root, args, %{context: %{cur_user: user}}) do
    CMS.create_content(args.part, %Accounts.User{id: user.id}, args)
  end

  def update_content(_root, args, _info), do: ORM.update(args.passport_source, args)
  def delete_content(_root, %{passport_source: content}, _info), do: ORM.delete(content)

  # #######################
  # part reaction ..
  # #######################
  def reaction(_root, ~m(id part action)a, %{context: %{cur_user: user}}) do
    CMS.reaction(part, action, id, %Accounts.User{id: user.id})
  end

  def undo_reaction(_root, ~m(id part action)a, %{context: %{cur_user: user}}) do
    CMS.undo_reaction(part, action, id, user.id)
  end

  def reaction_users(_root, ~m(id action part filter)a, _info) do
    CMS.reaction_users(part, action, id, filter)
  end

  # #######################
  # category ..
  # #######################
  def paged_categories(_root, ~m(filter)a, _info), do: Category |> ORM.find_all(filter)

  def create_category(_root, ~m(title)a, %{context: %{cur_user: user}}) do
    CMS.create_category(%Category{title: title}, %Accounts.User{id: user.id})
  end

  def update_category(_root, ~m(id title)a, %{context: %{cur_user: _}}) do
    CMS.update_category(~m(%Category id title)a)
  end

  def set_category(_root, ~m(community_id category_id)a, %{context: %{cur_user: _}}) do
    CMS.set_category(%Community{id: community_id}, %Category{id: category_id})
  end

  def unset_category(_root, ~m(community_id category_id)a, %{context: %{cur_user: _}}) do
    CMS.unset_category(%Community{id: community_id}, %Category{id: category_id})
  end

  # #######################
  # thread ..
  # #######################
  def create_thread(_root, ~m(title raw)a, _info) do
    CMS.create_thread(~m(title raw)a)
  end

  def add_thread_to_community(_root, ~m(community_id thread_id)a, _info) do
    CMS.add_thread_to_community(~m(community_id thread_id)a)
  end

  # #######################
  # editors ..
  # #######################
  def add_editor(_root, ~m(community_id user_id title)a, _) do
    CMS.add_editor_to_community(
      %Accounts.User{id: user_id},
      %Community{id: community_id},
      title
    )
  end

  def delete_editor(_root, ~m(community_id user_id)a, _) do
    CMS.delete_editor(%Accounts.User{id: user_id}, %Community{id: community_id})
  end

  def update_editor(_root, ~m(community_id user_id title)a, _) do
    CMS.update_editor(%Accounts.User{id: user_id}, %Community{id: community_id}, title)
  end

  def community_editors(_root, ~m(id filter)a, _info) do
    CMS.community_members(:editors, %Community{id: id}, filter)
  end

  # #######################
  # tags ..
  # #######################
  def create_tag(_root, args, %{context: %{cur_user: user}}) do
    CMS.create_tag(args.part, args, %Accounts.User{id: user.id})
  end

  def delete_tag(_root, %{id: id}, _info), do: Tag |> ORM.find_delete(id)

  def set_tag(_root, ~m(community_id part id tag_id)a, _info) do
    CMS.set_tag(part, id, %Community{id: community_id}, %Tag{id: tag_id})
  end

  def unset_tag(_root, ~m(id part tag_id)a, _info), do: CMS.unset_tag(part, id, %Tag{id: tag_id})

  def get_tags(_root, ~m(community_id part)a, _info) do
    CMS.get_tags(%Community{id: community_id}, part)
  end

  def get_tags(_root, ~m(filter)a, _info), do: CMS.get_tags(filter)

  # #######################
  # community subscribe ..
  # #######################
  def subscribe_community(_root, ~m(community_id)a, %{context: %{cur_user: cur_user}}) do
    CMS.subscribe_community(%Accounts.User{id: cur_user.id}, %Community{id: community_id})
  end

  def unsubscribe_community(_root, ~m(community_id)a, %{context: %{cur_user: cur_user}}) do
    CMS.unsubscribe_community(%Accounts.User{id: cur_user.id}, %Community{id: community_id})
  end

  def community_subscribers(_root, ~m(id filter)a, _info) do
    CMS.community_members(:subscribers, %Community{id: id}, filter)
  end

  def set_community(_root, ~m(part id community_id)a, _info) do
    CMS.set_community(part, id, %Community{id: community_id})
  end

  def unset_community(_root, ~m(part id community_id)a, _info) do
    CMS.unset_community(part, id, %Community{id: community_id})
  end

  # #######################
  # comemnts ..
  # #######################
  def paged_comments(_root, ~m(id part filter)a, _info), do: CMS.list_comments(part, id, filter)

  def create_comment(_root, ~m(part id body)a, %{context: %{cur_user: user}}) do
    CMS.create_comment(part, id, %Accounts.User{id: user.id}, body)
  end

  def delete_comment(_root, ~m(part id)a, _info) do
    CMS.delete_comment(part, id)
  end

  def reply_comment(_root, ~m(part id body)a, %{context: %{cur_user: user}}) do
    CMS.reply_comment(part, id, %Accounts.User{id: user.id}, body)
  end

  def like_comment(_root, ~m(part id)a, %{context: %{cur_user: user}}) do
    CMS.like_comment(part, id, %Accounts.User{id: user.id})
  end

  def undo_like_comment(_root, ~m(part id)a, %{context: %{cur_user: user}}) do
    CMS.undo_like_comment(part, id, %Accounts.User{id: user.id})
  end

  def dislike_comment(_root, ~m(part id)a, %{context: %{cur_user: user}}) do
    CMS.dislike_comment(part, id, %Accounts.User{id: user.id})
  end

  def undo_dislike_comment(_root, ~m(part id)a, %{context: %{cur_user: user}}) do
    CMS.undo_dislike_comment(part, id, %Accounts.User{id: user.id})
  end
end
