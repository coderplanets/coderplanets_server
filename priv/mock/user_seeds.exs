# use /test/support/populater

import MastaniServer.Factory

default_user = %{
  username: "mydearxym2",
  nickname: "simon",
  bio: "i am from seed",
  company: "infomedia"
}

# db_insert(:user, default_user)
db_insert_multi!(:user)
