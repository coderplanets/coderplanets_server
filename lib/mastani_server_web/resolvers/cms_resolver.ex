defmodule MastaniServerWeb.Resolvers.CMS do
  @moduledoc false

  import ShortMaps
  import Ecto.Query, warn: false

  alias MastaniServer.{CMS, Accounts}
  alias MastaniServer.CMS.{Post, Job, Community, Category, Tag, Thread}
  alias Helper.ORM

  # #######################
  # community ..
  # #######################
  def community(_root, %{id: id}, _info), do: Community |> ORM.find(id)
  def community(_root, %{title: title}, _info), do: Community |> ORM.find_by(title: title)
  def community(_root, %{raw: raw}, _info), do: Community |> ORM.find_by(raw: raw)

  def community(_root, _args, _info), do: {:error, "please provide community id or title or raw"}
  def paged_communities(_root, ~m(filter)a, _info), do: Community |> ORM.find_all(filter)

  def create_community(_root, args, %{context: %{cur_user: user}}) do
    args = args |> Map.merge(%{user_id: user.id})
    Community |> ORM.create(args)
  end

  def update_community(_root, args, _info), do: Community |> ORM.find_update(args)

  def delete_community(_root, %{id: id}, _info), do: Community |> ORM.find_delete(id)

  # #######################
  # community thread (post, job)
  # #######################
  def post(_root, %{id: id}, _info), do: Post |> ORM.read(id, inc: :views)

  def paged_posts(_root, ~m(filter)a, _info), do: CMS.paged_content(Post, filter)

  def job(_root, %{id: id}, _info), do: Job |> ORM.read(id, inc: :views)
  def paged_jobs(_root, ~m(filter)a, _info), do: Job |> ORM.find_all(filter)

  def create_content(_root, args, %{context: %{cur_user: user}}) do
    CMS.create_content(args.thread, %Accounts.User{id: user.id}, args)
  end

  def update_content(_root, args, _info), do: ORM.update(args.passport_source, args)
  def delete_content(_root, %{passport_source: content}, _info), do: ORM.delete(content)

  # TODO: rename
  # def pin_post(_root, %{id: id, pin: true}, %{context: %{cur_user: user}}) do
  def pin_post(_root, %{id: id}, %{context: %{cur_user: user}}) do
    CMS.set_flag(Post, id, %{pin: true}, user)
  end

  # #######################
  # thread reaction ..
  # #######################
  def reaction(_root, ~m(id thread action)a, %{context: %{cur_user: user}}) do
    CMS.reaction(thread, action, id, user)
  end

  def undo_reaction(_root, ~m(id thread action)a, %{context: %{cur_user: user}}) do
    CMS.undo_reaction(thread, action, id, user)
  end

  def reaction_users(_root, ~m(id action thread filter)a, _info) do
    CMS.reaction_users(thread, action, id, filter)
  end

  # #######################
  # category ..
  # #######################
  def paged_categories(_root, ~m(filter)a, _info), do: Category |> ORM.find_all(filter)

  def create_category(_root, ~m(title raw)a, %{context: %{cur_user: user}}) do
    CMS.create_category(%Category{title: title, raw: raw}, %Accounts.User{id: user.id})
  end

  def delete_category(_root, %{id: id}, _info), do: Category |> ORM.find_delete(id)

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
  def paged_threads(_root, ~m(filter)a, _info), do: Thread |> ORM.find_all(filter)

  def create_thread(_root, ~m(title raw index)a, _info),
    do: CMS.create_thread(~m(title raw index)a)

  def set_thread(_root, ~m(community_id thread_id)a, _info) do
    CMS.set_thread(%Community{id: community_id}, %Thread{id: thread_id})
  end

  def unset_thread(_root, ~m(community_id thread_id)a, _info) do
    CMS.unset_thread(%Community{id: community_id}, %Thread{id: thread_id})
  end

  # #######################
  # editors ..
  # #######################
  def set_editor(_root, ~m(community_id user_id title)a, _) do
    CMS.set_editor(
      %Accounts.User{id: user_id},
      %Community{id: community_id},
      title
    )
  end

  def unset_editor(_root, ~m(community_id user_id)a, _) do
    CMS.unset_editor(%Accounts.User{id: user_id}, %Community{id: community_id})
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
    CMS.create_tag(args.thread, args, %Accounts.User{id: user.id})
  end

  def delete_tag(_root, %{id: id}, _info), do: Tag |> ORM.find_delete(id)

  def update_tag(_root, args, _info), do: CMS.update_tag(args)

  def set_tag(_root, ~m(community_id thread id tag_id)a, _info) do
    CMS.set_tag(thread, id, %Community{id: community_id}, %Tag{id: tag_id})
  end

  def unset_tag(_root, ~m(id thread tag_id)a, _info),
    do: CMS.unset_tag(thread, id, %Tag{id: tag_id})

  def get_tags(_root, ~m(community_id thread)a, _info) do
    CMS.get_tags(%Community{id: community_id}, thread)
  end

  def get_tags(_root, ~m(community thread)a, _info) do
    CMS.get_tags(%Community{raw: community}, thread)
  end

  def get_tags(_root, %{thread: _thread}, _info) do
    {:error, "community_id or community is needed"}
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

  def set_community(_root, ~m(thread id community_id)a, _info) do
    CMS.set_community(thread, id, %Community{id: community_id})
  end

  def unset_community(_root, ~m(thread id community_id)a, _info) do
    CMS.unset_community(thread, id, %Community{id: community_id})
  end

  # #######################
  # comemnts ..
  # #######################
  def paged_comments(_root, ~m(id thread filter)a, _info),
    do: CMS.list_comments(thread, id, filter)

  def create_comment(_root, ~m(thread id body)a, %{context: %{cur_user: user}}) do
    CMS.create_comment(thread, id, %Accounts.User{id: user.id}, body)
  end

  def delete_comment(_root, ~m(thread id)a, _info) do
    CMS.delete_comment(thread, id)
  end

  def reply_comment(_root, ~m(thread id body)a, %{context: %{cur_user: user}}) do
    CMS.reply_comment(thread, id, %Accounts.User{id: user.id}, body)
  end

  def like_comment(_root, ~m(thread id)a, %{context: %{cur_user: user}}) do
    CMS.like_comment(thread, id, %Accounts.User{id: user.id})
  end

  def undo_like_comment(_root, ~m(thread id)a, %{context: %{cur_user: user}}) do
    CMS.undo_like_comment(thread, id, %Accounts.User{id: user.id})
  end

  def dislike_comment(_root, ~m(thread id)a, %{context: %{cur_user: user}}) do
    CMS.dislike_comment(thread, id, %Accounts.User{id: user.id})
  end

  def undo_dislike_comment(_root, ~m(thread id)a, %{context: %{cur_user: user}}) do
    CMS.undo_dislike_comment(thread, id, %Accounts.User{id: user.id})
  end

  def stamp_passport(_root, ~m(user_id rules)a, %{context: %{cur_user: _user}}) do
    # IO.inspect rules, label: "in resolver"
    # IO.inspect Jason.decode!(rules), label: "in resolver decode"
    CMS.stamp_passport(%Accounts.User{id: user_id}, rules)
  end
end
