


## run your project

```sh
  env MIX_ENV=mock iex -S mix

  mix test.watch test/mastani_server/cms/cms_passport_test.exs --only wip

  mix ecto.gen.migration add_xxx


  env MIX_ENV=test mix ecto.drop
  env MIX_ENV=test mix ecto.create

  support history in iex: 
  bash: export ERL_AFLAGS="-kernel shell_history enabled"
  fish: set -g -x ERL_AFLAGS "-kernel shell_history enabled"
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
