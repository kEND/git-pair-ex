defmodule GitPairEx.CLI do
  alias GitPairEx.Command

  def main(argv) do
    # parse args ...
    # return :help if the -h switch is supplied
    # pass to process
    argv
    |> split_on_equal()
    |> parse_args()
    |> process()
  end

  def split_on_equal(argv), do: argv |> Enum.map(&String.split(&1, "=")) |> List.flatten()

  def parse_args(argv) do
    # IO.inspect(argv)

    parse =
      OptionParser.parse(argv,
        strict: [
          help: :boolean,
          global: :boolean,
          local: :boolean,
          file: :string,
          message: :string,
          amend: :boolean,
          edit: :boolean,
          patch: :boolean,
          version: :boolean,
          quiet: :boolean,
          dry_run: :boolean
        ],
        aliases: [h: :help, m: :message, e: :edit, p: :patch, v: :version, q: :quiet]
      )

    case set_config_location(parse) do
      {[ {:help, true} | _rest], _, _} ->
        :help

      {[ {:version, true} | _rest], _, _} ->
        :version

      {_, ["add", abbr, email], opts} ->
        {:add, abbr, email, opts}

      {_, ["status"], opts} ->
        {:status, opts}

      {_, ["st"], opts} ->
        {:status, opts}

      {_, ["clear"], opts} ->
        {:clear, opts}

      {_, ["show-authors"], opts} ->
        {:show, opts}

      {_, ["remove", abbr], opts} ->
        {:remove, abbr, opts}

      {commit_opts, ["commit"], opts} ->
        {:commit, commit_opts, opts}

      {commit_opts, ["ci"], opts} ->
        {:commit, commit_opts, opts}

      {_, [abbr1, abbr2], opts} ->
        {:base, [abbr1, abbr2], opts}

      _ ->
        IO.inspect(set_config_location(parse))
        :help
    end
  end

  defp set_config_location({flags, args, _opts}) do
    opts = []
    opts = if flags[:global], do: ["--global"] ++ opts, else: opts
    opts = if flags[:local], do: ["--local"] ++ opts, else: opts
    opts = if flags[:file], do: ["--file", flags[:file]] ++ opts, else: opts

    flags = Enum.reject(flags, fn {k,_v} -> k in [:file, :global, :local] end)

    {flags, args, opts}
  end

  def reconstitute_commit_options(opts) do
    opts
    |> Enum.map(fn opt ->
      case opt do
        {k, true} -> [String.replace("--#{k}", "_", "-")]
        {k, false} -> [String.replace("--no-#{k}", "_", "-")]
        {k, v} -> ["--#{k}", v]
      end
    end)
    |> List.flatten()
  end

  def process({:commit, commit_opts, opts}) do
    commit_opts
    |> reconstitute_commit_options()
    |> Command.commit(opts)
    |> IO.puts()
  end

  def process({:base, abbrs, opts}) do
    output = Command.base(abbrs, opts)
    IO.puts(output)
  end

  def process({:add, abbr, email, opts}) do
    output = Command.add(abbr, email, opts)
    IO.puts(output)
  end

  def process({:clear, opts}) do
    output = Command.clear(opts)
    IO.puts(output)
  end

  def process({:show, opts}) do
    output = Command.show_authors(opts)
    IO.puts(output)
  end

  def process({:remove, abbr, opts}) do
    output = Command.remove(abbr, opts)
    IO.puts(output)
  end

  def process(:version) do
    IO.puts("git-pair #{version()}")
  end

  def process(:help) do
    usage = """
    git-pair #{version()}

    USAGE:
    git-pair [OPTIONS] <SUBCOMMAND>
    git-pair [OPTIONS] <ABBR1> <ABBR2>         ;   sets the pair by their abbreviations

    FLAGS:
        -h, --help       Prints help information
        -v, --version    Prints version information [NImp]

    OPTIONS:
            --global     Target git config for storing/retrieving authors [default: --local]
                            --global   ~/.gitconfig     Your system
                            --local   ./.git/config     Your project

    SUBCOMMANDS:
        add abbr 'Person <emailaddress>'    Add an author, e.g. `git-pair add js 'John Smith <jsmith@example.com>'
        clear                               Clears the pair
        help                                Prints this message
        remove abbr                         Remove an author by abbreviation
        show-authors                        Show list of authors
        status, st                          Returns `git status` with pairing status
        <more>                              many [NImp]
    """

    IO.puts(usage)
  end

  def process({:status, opts}) do
    {git_status, 0} = System.cmd("git", ["status"])

    IO.puts(git_status <> Command.status(opts))
  end

  defp version, do: Application.spec(:git_pair_ex, :vsn) |> to_string()
end
