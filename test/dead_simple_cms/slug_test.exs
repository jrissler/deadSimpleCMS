defmodule DeadSimpleCms.SlugTest do
  use ExUnit.Case, async: true

  alias DeadSimpleCms.Slug

  describe "normalize/1" do
    test "returns nil when slug is nil" do
      assert Slug.normalize(nil) == nil
    end

    test "downcases and trims leading/trailing whitespace" do
      assert Slug.normalize("  Hello World  ") == "hello-world"
      assert Slug.normalize("\n\tHello\t\n") == "hello"
    end

    test "collapses all whitespace runs into a single hyphen" do
      assert Slug.normalize("hello   world") == "hello-world"
      assert Slug.normalize("hello\tworld") == "hello-world"
      assert Slug.normalize("hello \n world") == "hello-world"
      assert Slug.normalize("hello \r\n \t world") == "hello-world"
    end

    test "removes characters that are not a-z, 0-9, or hyphen" do
      assert Slug.normalize("Hello, world!") == "hello-world"
      assert Slug.normalize("a_b*c@d") == "abcd"
      assert Slug.normalize("100% legit") == "100-legit"
      assert Slug.normalize("rock&roll") == "rockroll"
      assert Slug.normalize("naïve façade") == "nave-faade"
      assert Slug.normalize("你好 世界") == ""
    end

    test "collapses multiple hyphens into a single hyphen" do
      assert Slug.normalize("hello---world") == "hello-world"
      assert Slug.normalize("hello - - - world") == "hello-world"
      assert Slug.normalize("hello--   --world") == "hello-world"
    end

    test "trims hyphens from the beginning and end" do
      assert Slug.normalize("-hello-") == "hello"
      assert Slug.normalize("----hello----") == "hello"
      assert Slug.normalize("  -- hello --  ") == "hello"
    end

    test "keeps existing single hyphens and alphanumerics intact" do
      assert Slug.normalize("already-a-slug-123") == "already-a-slug-123"
      assert Slug.normalize("MiXeD-Case-123") == "mixed-case-123"
    end

    test "returns empty string when input normalizes to nothing" do
      assert Slug.normalize("   ") == ""
      assert Slug.normalize("!!!") == ""
      assert Slug.normalize("--") == ""
      # various dash-like unicode chars are removed
      assert Slug.normalize("—–—") == ""
    end

    test "is idempotent (normalizing twice yields same result)" do
      input = "  Hello,   WORLD!!!  "
      normalized = Slug.normalize(input)

      assert Slug.normalize(normalized) == normalized
    end
  end
end
