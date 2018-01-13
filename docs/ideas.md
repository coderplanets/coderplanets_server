
## TODO TATAY: 

  [ ] use tags to *explore* the filter
  [ ] comments complete with *filter*  *sort*
  [x] post viewcount / one page *CRUD* 
  [x] create / *update* complete
  [ ] posts ui
  [x] think thoungh *communities* models
  [x] *star/favorite/watch*
  [ ] community *has-many* posts ..
  [x] posts tags  *many-to-many*
  --------------------------------------
  [ ] a trigger example
  [ ] *delivery* model

## roadmap
  [ ] communities: post, tuts, video, meetup, job
  [x] basic favorite, star, watch
  [ ] delivery / trigger
  [ ] user map
  [x] cheatsheet
  [ ] 每日妹子图
  [ ] 如果是投票： 增加一个subviewer:vote 字段， 在 one_content 的时候 preload it？ 

## CLI

 mix phx.gen.context CMS Author cms_authors role:string user_id:references:users:unique
 mix ecto.migrate
 mix ecto.gen.migration remove_link_table

## posts

[concepts of cache](https://dev-blog.apollodata.com/the-concepts-of-graphql-bc68bd819be3)
[announcing-apollo-cache-persist](https://dev-blog.apollodata.com/announcing-apollo-cache-persist-cb05aec16325)
[new trace view in apollo engine](https://dev-blog.apollodata.com/the-new-trace-view-in-apollo-engine-566b25bdfdb0)
[GraphQL breif](https://alligator.io/graphql/introduction-graphql-queries/)

[setup-elixir for tracing](https://www.apollographql.com/docs/engine/setup-elixir.html)

## packages 

[ApolloTracing (for Elixir)](https://github.com/sikanhe/apollo-tracing-elixir)
[apollo-cache-persist](https://github.com/apollographql/apollo-cache-persist)

