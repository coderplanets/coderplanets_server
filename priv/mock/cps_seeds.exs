alias GroupherServer.CMS

# NOTE: seed order matters
CMS.seed_communities(:home)
CMS.seed_communities(:city)
CMS.seed_communities(:editor)
CMS.seed_communities(:ui)
CMS.seed_communities(:blockchain)
CMS.seed_communities(:devops)
CMS.seed_communities(:database)
CMS.seed_communities(:framework)
CMS.seed_communities(:pl)

CMS.seed_set_category(
  ["css", "bootstrap", "semantic-ui", "material-design", "fabric", "antd"],
  "ui"
)

CMS.seed_set_category(
  ["ios", "android", "flutter", "ionic", "react-native", "weex", "xamarin", "nativescript"],
  "mobile"
)

CMS.seed_set_category(["ethereum", "bitcoin"], "blockchain")

CMS.seed_set_category(["tensorflow"], "ai")

CMS.seed_set_category(
  [
    "taro",
    "webrtc",
    "wasm",
    "backbone",
    "d3",
    "react",
    "angular",
    "meteor",
    "vue",
    "electron"
  ],
  "frontend"
)

CMS.seed_set_category(
  [
    "django",
    "drupal",
    "eggjs",
    "nestjs",
    "nuxtjs",
    "laravel",
    "nodejs",
    "phoenix",
    "rails",
    "sails",
    "zend",
    "oracle",
    "hive",
    "spark",
    "hadoop",
    "cassandra",
    "elasticsearch",
    "sql-server",
    "neo4j",
    "mongodb",
    "mysql",
    "postgresql",
    "redis"
  ],
  "backend"
)
