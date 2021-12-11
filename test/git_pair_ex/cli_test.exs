defmodule GitPairEx.CLITest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  describe "git-pair CLI" do
    test "prints usage instructions when the help switch is supplied" do
      execute_main = fn ->
        GitPairEx.CLI.main(["-h"])
      end

      assert capture_io(execute_main) =~ "USAGE"
    end

    test "prints git status with git-pair status when supplying 'status'" do
      execute_main = fn ->
        GitPairEx.CLI.main(["status"])
      end

      output = assert capture_io(execute_main)

      assert output =~ "On branch"
      assert output =~ "pair"
    end

    test "prints git status with git-pair status when supplying 'st'" do
      execute_main = fn ->
        GitPairEx.CLI.main(["st"])
      end

      output = assert capture_io(execute_main)

      assert output =~ "On branch"
      assert output =~ "pair"
    end

    test "adds an author if given an unused abbreviation and email" do
      execute_main = fn ->
        GitPairEx.CLI.main([
          "--file",
          "priv/git/config2",
          "add",
          "aa",
          "Arthur Ashe <aashe@example.com>"
        ])
      end

      assert capture_io(execute_main) ==
               "aa - Arthur Ashe <aashe@example.com> added as a git-pair author.\n"
    end

    test "sets the pair if given two abbreviations that match author keys" do
      GitPairEx.Command.add("aa", "Arthur Ashe <aashe@example.com>", [
        "--file",
        "priv/git/config2"
      ])

      GitPairEx.Command.add("zz", "Zander Zink <zzink@example.com>", [
        "--file",
        "priv/git/config2"
      ])

      execute_main = fn ->
        GitPairEx.CLI.main(["--file", "priv/git/config2", "aa", "zz"])
      end

      assert capture_io(execute_main) == "Arthur Ashe and Zander Zink are pairing.\n"
    end

    test "clears the pair" do
      GitPairEx.Command.add("aa", "Arthur Ashe <aashe@example.com>", [
        "--file",
        "priv/git/config2"
      ])

      GitPairEx.Command.add("zz", "Zander Zink <zzink@example.com>", [
        "--file",
        "priv/git/config2"
      ])

      GitPairEx.Command.base(["aa", "zz"], ["--file", "priv/git/config2"])

      execute_main = fn ->
        GitPairEx.CLI.main(["--file", "priv/git/config2", "status"])
      end

      assert capture_io(execute_main) =~
               "Arthur Ashe + Zander Zink <aashe@example.com> are pairing."

      execute_main = fn ->
        GitPairEx.CLI.main(["--file", "priv/git/config2", "clear"])
      end

      assert capture_io(execute_main) == "Pair cleared.\n"
    end

    test "removes an author if given an abbreviation" do
      GitPairEx.Command.add("bb", "Billy Boyd <bboyd@example.com>", [
        "--file",
        "priv/git/config2"
      ])

      execute_main = fn ->
        GitPairEx.CLI.main(["--file", "priv/git/config2", "remove", "bb"])
      end

      assert capture_io(execute_main) == "'bb' removed.\n"
    end

    test "shows the authors" do
      execute_main = fn ->
        GitPairEx.CLI.main(["--file", "priv/git/config2", "show-authors"])
      end

      assert capture_io(execute_main) ==
               "\nAuthors\n========\naa - Arthur Ashe <aashe@example.com>\nzz - Zander Zink <zzink@example.com>\n\n"
    end

    test "displays git-pair version" do
      execute_main = fn ->
        GitPairEx.CLI.main(["-v"])
      end

      assert capture_io(execute_main) == "git-pair 0.1.0\n"
    end
  end

  describe "committing" do
    setup do
      config_location = ["--file", "priv/git/config"]

      GitPairEx.Command.add("js", "John Smith <jsmith@example.com>", config_location)
      GitPairEx.Command.add("hz", "Hilary Zane <hzane@example.com>", config_location)
      System.shell("git config --file priv/git/config --unset git-pair.pair")
      System.shell("git checkout -- priv/git/config2")

      on_exit(fn ->
        System.shell("git config --file priv/git/config --remove-section git-pair.authors")
        System.shell("git config --file priv/git/config --unset git-pair.pair")
        System.shell("git checkout -- priv/git/config")
        System.shell("git checkout -- priv/git/config2")
      end)

      [config: config_location]
    end

    test "commit/3 commits changes using the pair as author", %{config: config_location} do
      System.shell("git stash push -- . ':(exclude)priv/git/config' ':(exclude)priv/git/config2'")
      {status_output, _} = System.cmd("git", ["status"])
      ["On branch " <> original_branch | _rest] = String.split(status_output, "\n", parts: 2)

      {short_sha, 0} = System.cmd("git", ["rev-parse", "--short", "HEAD"])

      System.shell("git switch --force-create testing")

      GitPairEx.Command.base(["hz", "js"], config_location)
      GitPairEx.Command.status(config_location)

      System.shell("git add priv/git/config")

      _expected_output = """
      [testing 174930d] This is a test commit.
      1 file changed, 1 insertions(+)
      """

      args = ["-m", "This is a test commit."]

      execute_main = fn ->
        GitPairEx.CLI.main(["--file", "priv/git/config", "commit"] ++ args)
      end

      output = capture_io(execute_main)


      case System.cmd("git", ["rev-parse", "--short", "HEAD"]) do
        {^short_sha, 0} ->
          nil
        {other_sha, 0} ->
          System.shell("git reset --hard #{other_sha}")
      end
      System.shell("git checkout #{original_branch}")
      System.shell("git stash pop")

      assert output =~ ~r/\[testing .{7}\] This is a test commit./
      assert output =~ "Hilary Zane + John Smith <hzane@example.com>"
      assert output =~ "1 file changed, 4 insertions(+)"
    end
  end

  describe "reconstitute_commit_options/1" do
    test "yields arguments that `git commit` wants" do
      assert GitPairEx.CLI.reconstitute_commit_options(
               dry_run: true,
               message: "some message",
               amend: true,
               edit: false
             ) == ["--dry-run", "--message", "some message", "--amend", "--no-edit"]
    end
  end
end
