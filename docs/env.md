

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
env PORT=4001  MIX_ENV=mock mix phx.server
```

```sh
env MIX_ENV=mock mix run priv/repo/seeds.ex
```

## mock data

```sh
env MIX_ENV=mock iex -S mix phx.server
```

