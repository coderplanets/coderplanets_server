
本文档将介绍 `coderplanets_server` 的基本概况, 这需要你了解 Elixir 和 GraphQL 的
基础知识， 如果你对它们还不太了解，请参考
*https://elixir-lang.org/getting-started/introduction* 或 *https://www.howtographql.com/*

> NOTE: since coderplanets_server is build on top of [mastani-stack](https://github.com/mastani-stack), the whole project is under namespace of `Mastani`

## Tech Stack

Here's a curated list of packages that used by CPS project. However, the best way to see a complete list of the dependencies is to check [mix.ex](https://github.com/coderplanets/coderplanets_server/blob/dev/mix.exs).

### Core

- [Elixir](https://github.com/elixir-lang/elixir)
- [Phoenix Framework](https://github.com/phoenixframework)
  - [Phoenix](https://github.com/phoenixframework/phoenix)
  - [Ecto](https://github.com/elixir-ecto/ecto)
  - [Postgrex](https://github.com/elixir-ecto/postgrex)
- [Absinthe Stack](https://github.com/absinthe-graphql)
  - [Absinthe](https://github.com/absinthe-graphql/absinthe)
  - [Dataloader](https://github.com/absinthe-graphql/dataloader)
  - [Apollo Tracing](https://github.com/sikanhe/apollo-tracing-elixir)

### testing
- [test suite](https://hexdocs.pm/phoenix/testing.html#content)

### lint

- [Credo](https://github.com/rrrene/credo)
- [Dialyxir](https://github.com/jeremyjh/dialyxir)



## Project Structure

Let's start with understanding why we have chosen our particular structure. since Phoenix 1.3 has a lots of major changes, we recommend you to watch the full [video](https://www.youtube.com/watch?v=tMO28ar0lW8).

In any case, here's the TL;DR:

- You will write your app in the `lib` and `test` folder. This is the folder you will spend most of your time in.
- Configurations are locate in `config` folder
- migrations and mock seeds in `priv` folder
- Most of generator and utils cmds are validable in Makefile, use `make help` see the full list

### `lib/`

- `mastani_server/`  we split our logic code into contexts. a context will group
  related functionality which located in context's `delegates` dir,  By using contexts, we decouple and isolate our systems into *5* manageable, independent parts:
  - `accounts/` handle account-related logic like: register, profile, mailbox, achievement, billing, customization ...
  - `cms/` handle content-releated logic like: community curd/operation/reactions, contents(posts, jobs, videos, ..) CURD/operation/reactions ...
  - `delivery/` handle msg-related logic like: user mentions, system notifications ...
  - `log/` record important actions
  - `statistics/` handle statistics like: user contributes, community contributes ...
  
- `mastani_server_web/` handle "web-interface" only logic
  - `resolvers/` graphql resolvers based on Context
  - `schema/` graphql schema based on Context, include queries & mutations
  - `middleware/` common logic like authorize, passport, pagesize_check ...
  - `channels/` hanlde realtime communitications like graphql subscription ...
  - `helper/` As the name suggests this folder reusable modules like query_builder, orms ...

### `test/`

- `master_server/` test all the "domain logic"
- `master_server_web/` test all the web logic, most are graphql interface
- `helper/` test all helper functions

### `config/`

config files based on dierent env

### `deploy/`

- `dev/` dev server packer, Docker setttings ..
- `production/` production server packer, Docker setttings ..

### `priv/`

- `mock/` seeds script for init
- `repo/` migrations files
