defmodule GitPairEx.CommandTest do
  use ExUnit.Case

  describe "show" do
    test "returns list of authors - from local" do
      # this test is brittle as it depends on your local ./.git/config
      #
      # it was a useful test during the initial build out of the tool.
      # from a clean ./.git/config run the following commands to make this
      # test pass:
      #
      #   `git-pair add js 'John Smith <jsmith+local@example.com>'`
      #   `git-pair add hz 'Hillary Zane <hzane+local@example.com>'`
      #
      expected_author_list = """

      Authors
      ========
      js - John Smith <jsmith+local@example.com>
      hz - Hillary Zane <hzane+local@example.com>
      """

      assert GitPairEx.Command.show_authors() == expected_author_list
    end

    test "returns list of authors - from global" do
      # this test is brittle as it depends on your global .gitconfig
      #
      # it was a useful test during the initial build out of the tool.
      # from a clean ~/.gitconfig run the following commands to make this
      # test pass:
      #
      #   `git-pair --global add js 'John Smith <jsmith+global@example.com>'`
      #   `git-pair --global add hz 'Hillary Zane <hzane+global@example.com>'`
      #
      expected_author_list = """

      Authors
      ========
      js - John Smith <jsmith+global@example.com>
      hz - Hillary Zane <hzane+global@example.com>
      """

      assert GitPairEx.Command.show_authors(["--global"]) == expected_author_list
    end
  end

  describe "commands" do
    setup do
      config_location = ["--file", "priv/git/config"]

      GitPairEx.Command.add("js", "John Smith <jsmith@example.com>", config_location)
      GitPairEx.Command.add("hz", "Hilary Zane <hzane@example.com>", config_location)
      System.shell("git config --file priv/git/config --unset git-pair.pair")

      on_exit(fn ->
        System.shell("git config --file priv/git/config --remove-section git-pair.authors")
        System.shell("git config --file priv/git/config --unset git-pair.pair")
        System.shell("git checkout -- priv/git/config")
        System.shell("git checkout -- priv/git/config2")
      end)

      [config: config_location]
    end

    test "add/3 adds an author to the config", %{config: config_location} do
      refute GitPairEx.Command.show_authors(config_location) =~
               "er - Erin Rooney <erooney@example.com>"

      GitPairEx.Command.add("er", "Erin Rooney <erooney@example.com>", config_location)

      assert GitPairEx.Command.show_authors(config_location) =~
               "er - Erin Rooney <erooney@example.com>"
    end

    test "remove/2 removes an author from the config", %{config: config_location} do
      assert GitPairEx.Command.show_authors(config_location) =~
               "js - John Smith <jsmith@example.com>"

      GitPairEx.Command.remove("js", config_location)

      refute GitPairEx.Command.show_authors(config_location) =~
               "js - John Smith <jsmith@example.com>"
    end

    test "find/2 an author returning author name and email", %{config: config_location} do
      assert GitPairEx.Command.find("hz", config_location) == "Hilary Zane <hzane@example.com>"
    end

    test "find/2 returns '' when abbreviation doesn't match any author", %{
      config: config_location
    } do
      assert GitPairEx.Command.find("aa", config_location) == ""
    end

    test "status/1 shows the current no pair author combo if not set", %{config: config_location} do
      assert GitPairEx.Command.status(config_location) ==
               "No paired author is set.  Run 'git-pair ab cd' to set the pair."
    end

    test "base/2 sets the pair from known pairs and status/2 confirms it", %{
      config: config_location
    } do
      assert GitPairEx.Command.base(["hz", "js"], config_location) ==
               "Hilary Zane and John Smith are pairing."

      assert GitPairEx.Command.status(config_location) ==
               "Hilary Zane + John Smith <hzane@example.com> are pairing."
    end

    test "clear/1 unsets the pair author combo", %{config: config_location} do
      GitPairEx.Command.base(["hz", "js"], config_location)

      assert GitPairEx.Command.status(config_location) ==
               "Hilary Zane + John Smith <hzane@example.com> are pairing."

      assert GitPairEx.Command.clear(config_location) == "Pair cleared."

      assert GitPairEx.Command.status(config_location) ==
               "No paired author is set.  Run 'git-pair ab cd' to set the pair."
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

      output = GitPairEx.Command.commit(args, config_location)

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
end
