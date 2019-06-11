# .dialyzer_ignore.exs
# about no_return see: https://github.com/jeremyjh/dialyxir/issues/210
[
  # {short_description}
  {":0:unknown_type Unknown type: Result.Object.t/0."},
  # {file, warning_type}
  {"lib/groupher_server/cms/utils/loader.ex", :no_return},
  # {file, warning_type}
  {"lib/groupher_server_web/schema.ex", :no_return},
  # {file, warning_type}
  {"lib/groupher_server_web/schema.ex", :no_return}
]
