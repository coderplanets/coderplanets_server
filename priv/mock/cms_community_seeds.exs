import GroupherServer.Support.Factory

alias Helper.ORM
alias GroupherServer.CMS

# communities = ["js", "java", "nodejs", "elixir", "c", "python", "ruby", "lisp"]
# communities = ["php", "julia", "rust", "cpp", "csharp", "clojure", "dart", "go", "kotlin"]
communities = ["scala", "haskell", "swift", "typescript", "lua", "racket"]
# threads = ["posts", "tuts", "users", "map", "radar", "cheatsheet", "jobs"]

{:ok, threads} = ORM.find_all(CMS.Thread, %{page: 1, size: 30})
thread_ids = threads.entries |> Enum.map(& &1.id)

# thread_ids =
# Enum.reduce(1..length(threads), [], fn cnt, acc ->
# IO.inspect(cnt, label: "cnt")

# {:ok, thread} =
# db_insert(:thread, %{
# title: threads |> Enum.at(cnt - 1),
# raw: threads |> Enum.at(cnt - 1)
# })

# acc ++ [thread]
# end)
# |> Enum.map(& &1.id)

Enum.each(communities, fn c ->
  {:ok, community} =
    db_insert(:community, %{
      title: c,
      desc: "#{c} is the my favorites",
      logo: "https://coderplanets.oss-cn-beijing.aliyuncs.com/icons/pl/#{c}.svg",
      raw: c
    })

  Enum.each(thread_ids, fn thread_id ->
    {:ok, _} =
      db_insert(:communities_threads, %{community_id: community.id, thread_id: thread_id})
  end)
end)
