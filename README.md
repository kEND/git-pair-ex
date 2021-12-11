# GitPairEx

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `git_pair_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:git_pair_ex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/git_pair_ex>.

###

Test suite may be fragile.  Specifically, `git` >= 2.30.0 is required because
we use `git switch` to help test `git commit`.

huh