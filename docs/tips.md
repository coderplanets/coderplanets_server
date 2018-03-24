

## run your project

```sh
  env MIX_ENV=mock iex -S mix
  alias MastaniServer.CMS
  import Ecto.Query, warn: false
  alias MastaniServer.Repo
  CMS.Post |> order_by(desc: :views) |> Repo.one
```
`recompile()` to recompile your project

[tips#6](https://medium.com/blackode/10-killer-elixir-tips-2-c5f87f8a70c8)

但是 config/config.ex 中配置的改变需要重新编译

## run cmd for specific env

```sh
env MIX_ENV=test mix ecto.setup
```

this cmd only preform on `mastani_server_test` databse


## prod

```sh
env PORT=4001  MIX_ENV=prod mix ecto.setup
```

```sh
env PORT=4001  MIX_ENV=prod mix phx.server
```


## mock 

```sh
env MIX_ENV=mock mix ecto.setup
```

```sh
env PORT=4001 MIX_ENV=mock mix phx.server
```

```sh
env MIX_ENV=mock mix run priv/mock/user_seeds.exs
```

## mock data

```sh
env MIX_ENV=mock iex -S mix phx.server
```

## Guardian

[胖子 comeonin 那集视频](https://www.youtube.com/watch?v=UK8KBnoidr4)
[Permissions pm doc](https://hexdocs.pm/guardian/Guardian.Permissions.Bitwise.html#content)
[Permissions blog doc](http://blog.overstuffedgorilla.com/simple-guardian-permissions/)
[api authentication blog](http://blog.overstuffedgorilla.com/simple-guardian-api-authentication/)

## packages

[翻页](https://snippets.aktagon.com/snippets/776-pagination-with-elixir-and-ecto)
[翻页](https://github.com/drewolson/scrivener_ecto)
[邮件](https://github.com/thoughtbot/bamboo)

[CI: circleci](https://blog.lelonek.me/elixir-continuous-integration-with-circleci-ceae93dbe011)
[错误报告](https://sentry.io/welcome/)
[sentry-elixir](https://github.com/getsentry/sentry-elixir)
[run phoenix in docker](https://blog.lelonek.me/how-to-run-phoenix-framework-application-inside-a-docker-container-b02817d860b4)


## snippets

examise.io ... 
[Elixir fishy coding lines and snippets](https://medium.com/blackode/elixir-fishy-coding-lines-and-snippets-7cdd995e5ad4)
[Elixir killer tips](https://medium.com/blackode/10-killer-elixir-tips-2a9be1bec9be)
[Elixir 专题](https://medium.com/blackode/tagged/elixir) 很棒


## keynote 

[ActiveRecord 和 Ecto 的比较](http://tony612.com/activerecord-vs-ecto)
