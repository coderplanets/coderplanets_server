# use /test/support/populater

import MastaniServer.Factory

default_user = %{
  username: "mydearxym",
  nickname: "simon",
  bio: "i am from seed",
  company: "infomedia"
}

db_insert(:user, default_user)
