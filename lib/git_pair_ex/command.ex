defmodule GitPairEx.Command do
  def show_authors(opts \\ ["--local"]) do
    {config_list, 0} = System.cmd("git", ["config", "--list"] ++ opts)

    authors =
      config_list
      |> String.split("\n")
      |> Enum.filter(&Regex.match?(~r/^git\-pair\.authors/, &1))
      |> Enum.map(fn line ->
        Regex.run(author_regex(), line, capture: :all_but_first) |> Enum.join(" - ")
      end)
      |> Enum.join("\n")

    """

    Authors
    ========
    #{authors}
    """
  end

  defp author_regex, do: ~r/^git-pair.authors.([^=]+)=(.+)$/

  def add(abbr, email, opts \\ ["--local"]) do
    {_, 0} = System.cmd("git", ["config"] ++ opts ++ ["git-pair.authors.#{abbr}", email])

    abbr <> " - " <> email <> " added as a git-pair author."
  end

  def find(abbr, opts \\ ["--local"]) do
    case System.cmd("git", ["config"] ++ opts ++ ["git-pair.authors.#{abbr}"]) do
      {author, 0} ->
        author |> String.trim()

      {_, 1} ->
        ""
    end
  end

  def remove(abbr, opts \\ ["--local"]) do
    {_, _} = System.cmd("git", ["config"] ++ opts ++ ["--unset", "git-pair.authors.#{abbr}"])

    "'#{abbr}' removed."
  end

  def status(opts \\ ["--local"]) do
    case System.cmd("git", ["config"] ++ opts ++ ["git-pair.pair"]) do
      {status, 0} ->
        status
        |> String.trim()
        |> Kernel.<>(" are pairing.")

      {_, 1} ->
        "No paired author is set.  Run 'git-pair ab cd' to set the pair."
    end
  end

  def base(abbrs, opts \\ ["--local"]) do
    case authors_exist(abbrs, opts) do
      [[name_1, email_1], [name_2, _email_2]] ->
        System.cmd(
          "git",
          ["config"] ++ opts ++ ["git-pair.pair", "#{name_1} + #{name_2} <#{email_1}>"]
        )

        "#{name_1} and #{name_2} are pairing."

      [[name, _], nil] ->
        "Only #{name} found. Use `git-pair add` to add missing author."

      [nil, [name, _]] ->
        "Only #{name} found. Use `git-pair add` to add missing author."

      [_, _] ->
        "Neither author found.  Use `git-pair add` to add missing authors."
    end
  end

  defp authors_exist(abbrs, opts) do
    abbrs
    |> Enum.map(&find(&1, opts))
    |> Enum.map(&Regex.run(~r/(?:"?([^"]*)"?\s)?(?:<?(.+@[^>]+)>?)/, &1, capture: :all_but_first))
  end

  def clear(opts \\ ["--local"]) do
    case System.cmd("git", ["config"] ++ opts ++ ["--unset", "git-pair.pair"]) do
      {_, 0} ->
        "Pair cleared."

      _ ->
        nil
    end
  end

  def get_pair(opts \\ ["--local"]) do
    case System.cmd("git", ["config"] ++ opts ++ ["git-pair.pair"]) do
      {author, 0} ->
        author |> String.trim()

      {_, 1} ->
        "No pair set. Try `git pair ab cd` to set a pair."
    end
  end

  def commit(args, opts \\ ["--local"]) do
    command_args = ["commit", "--author", get_pair(opts)] ++ args
    case System.cmd("git", command_args) do
      {output, 0} ->
        output

      {other, _} ->
        other
    end
  end
end
