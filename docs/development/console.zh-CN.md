
### console

Elixir/Phoenix 有和其他动态语言相似的 REPL 执行环境 - `iex`, 类似 Ruby 的 `irb`, Python
中的 `ipython` 等等。你可以使用 `make console` 或者 `make console.help` 查看帮
助: 

```text

  [valid console commands]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  console      : run iex
  ...................................
  console.dev  : run iex in dev env
  ...................................
  console.mock : run iex in mock env
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

```

注意: 原始的 iex 命令行工具功能较为单一， 所以这里的 console.* 命令在下层调用的加参数后的 iex 程序, 比如你运行 `make
console.mock` , 在执行时会转换成 `MIX_ENV=mock iex --erl "-kernel shell_history
enabled" -S mix`, 以支持命令历史等操作。
