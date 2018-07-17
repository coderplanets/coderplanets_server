%{
  configs: [
    %{
      name: "default",
      color: true,
      struct: true,
      files: %{
        included: ["lib/", "test/"],
        excluded: []
      },
      checks: [
        # alias nested modules in resolvers not work
        {Credo.Check.Design.AliasUsage, false},
        # For others you can also set parameters
        {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 100},
        # ... several checks omitted for readability ...
      ]
    }
  ]
}
