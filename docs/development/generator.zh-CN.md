
### generator

帮助在开发时快速生成一些样板代码， 使用 `make gen` 或 `make gen.help` 查看帮助。

```text

  [valid generators]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  gen.migration : generate migration fils
                | e.p  : gen.migration arg="add_name_to_users"
                | note : need to run "make migrate" later
  ..................................................................................
  gen.context   : generate a new context
                | e.p: make gen.context Accounts Credential credentials
                                        email:string:unique user_id:references:users
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

```



