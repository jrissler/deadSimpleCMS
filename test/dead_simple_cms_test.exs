defmodule DeadSimpleCmsTest do
  use ExUnit.Case, async: false

  @ex_aws_keys [:region, :access_key_id, :secret_access_key]

  setup do
    original_s3 = Application.get_env(:dead_simple_cms, :s3)
    original_ex_aws = Map.new(@ex_aws_keys, &{&1, Application.get_env(:ex_aws, &1)})

    on_exit(fn ->
      if original_s3,
        do: Application.put_env(:dead_simple_cms, :s3, original_s3),
        else: Application.delete_env(:dead_simple_cms, :s3)

      Enum.each(original_ex_aws, fn
        {key, nil} -> Application.delete_env(:ex_aws, key)
        {key, value} -> Application.put_env(:ex_aws, key, value)
      end)
    end)

    :ok
  end

  describe "ensure_ex_aws_configured/0" do
    test "with only a bucket, leaves the host's ex_aws config alone" do
      Application.put_env(:ex_aws, :region, "us-east-2")
      Application.put_env(:ex_aws, :access_key_id, "host-key")
      Application.put_env(:ex_aws, :secret_access_key, "host-secret")
      Application.put_env(:dead_simple_cms, :s3, bucket: "cms-bucket")

      assert DeadSimpleCms.ensure_ex_aws_configured() == :ok
      assert Application.get_env(:ex_aws, :region) == "us-east-2"
      assert Application.get_env(:ex_aws, :access_key_id) == "host-key"
      assert Application.get_env(:ex_aws, :secret_access_key) == "host-secret"
    end

    test "writes region and credentials to ex_aws when given" do
      Application.put_env(:dead_simple_cms, :s3, bucket: "cms-bucket", region: "us-west-1", access_key_id: "cms-key", secret_access_key: "cms-secret")

      assert DeadSimpleCms.ensure_ex_aws_configured() == :ok
      assert Application.get_env(:ex_aws, :region) == "us-west-1"
      assert Application.get_env(:ex_aws, :access_key_id) == "cms-key"
      assert Application.get_env(:ex_aws, :secret_access_key) == "cms-secret"
    end

    test "raises without a bucket" do
      Application.put_env(:dead_simple_cms, :s3, region: "us-east-1")

      assert_raise ArgumentError, ~r/bucket/, fn -> DeadSimpleCms.ensure_ex_aws_configured() end
    end

    test "raises without s3 config" do
      Application.delete_env(:dead_simple_cms, :s3)

      assert_raise ArgumentError, ~r/bucket/, fn -> DeadSimpleCms.ensure_ex_aws_configured() end
    end
  end

  describe "page_preview_url/1" do
    setup do
      on_exit(fn -> Application.delete_env(:dead_simple_cms, :page_preview_url) end)
    end

    test "fills :slug and :id into the host's template" do
      Application.put_env(:dead_simple_cms, :page_preview_url, "https://example.com/preview/:slug?page=:id")

      assert DeadSimpleCms.page_preview_url(%{slug: "about", id: "abc"}) == "https://example.com/preview/about?page=abc"
    end

    test "is nil when the setting is absent or the page has no slug yet" do
      assert DeadSimpleCms.page_preview_url(%{slug: "about", id: "abc"}) == nil

      Application.put_env(:dead_simple_cms, :page_preview_url, "/preview/:slug")
      assert DeadSimpleCms.page_preview_url(%{slug: nil, id: nil}) == nil
      assert DeadSimpleCms.page_preview_url(%{slug: "", id: nil}) == nil
    end
  end
end
