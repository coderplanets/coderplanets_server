import GroupherServer.Support.Factory
import Helper.Utils, only: [map_key_stringify: 1]

alias GroupherServer.{Accounts, CMS}

root_rules = %{
  "root" => true
}

github_profile = mock_attrs(:github_profile, %{login: "cms_root"}) |> map_key_stringify

{:ok, %{token: token, user: user}} = Accounts.github_signin(github_profile)
{:ok, _passport} = CMS.stamp_passport(root_rules, user)

IO.puts("========== create cms root done ! ===========================")
IO.puts("paste token string to brower localstorage (fmt: token: token)")
IO.puts("-------------------------------------------------------------")
IO.puts(token)
IO.puts("=============================================================")
