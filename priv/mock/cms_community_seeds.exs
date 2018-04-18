import MastaniServer.Factory

communities = ["js", "java", "nodejs", "elixir", "c", "python", "ruby", "lisp"]
threads = ["posts", "tuts", "users", "map", "videos", "news", "cheatsheet", "jobs"]

thread_ids =
  Enum.reduce(1..length(threads), [], fn cnt, acc ->
    IO.inspect(cnt, label: "cnt")

    {:ok, thread} =
      db_insert(:thread, %{
        title: threads |> Enum.at(cnt - 1),
        raw: threads |> Enum.at(cnt - 1)
      })

    acc ++ [thread]
  end)
  |> Enum.map(& &1.id)

Enum.each(communities, fn c ->
  {:ok, community} =
    db_insert(:community, %{
      title: c,
      desc: "#{c} is the my favorites",
      logo: "https://coderplanets.oss-cn-beijing.aliyuncs.com/icons/pl/#{c}.svg",
      raw: c,
      category: "编程语言"
    })

  Enum.each(thread_ids, fn thread_id ->
    {:ok, _} =
      db_insert(:communities_threads, %{community_id: community.id, thread_id: thread_id})
  end)
end)
