defmodule DeadSimpleCms.Uploaders.S3UploaderTest do
  use ExUnit.Case, async: false

  alias DeadSimpleCms.Uploaders.S3Uploader

  setup do
    original_s3 = Application.get_env(:dead_simple_cms, :s3)

    Application.put_env(:dead_simple_cms, :s3,
      region: "us-east-1",
      access_key_id: "test-access-key",
      secret_access_key: "test-secret-key",
      bucket: "test-bucket"
    )

    on_exit(fn ->
      if original_s3,
        do: Application.put_env(:dead_simple_cms, :s3, original_s3),
        else: Application.delete_env(:dead_simple_cms, :s3)
    end)

    :ok
  end

  describe "build_key/1" do
    test "builds a unique cms image key" do
      key = S3Uploader.build_key("contract.pdf")

      assert String.starts_with?(key, "uploads/cms_images/")
      assert String.ends_with?(key, "/contract.pdf")
    end

    test "sanitizes unsafe filename characters" do
      key = S3Uploader.build_key("Purchase Agreement (Final) #1.pdf")

      assert String.ends_with?(key, "/Purchase-Agreement--Final---1.pdf")
      refute key =~ " "
      refute key =~ "("
      refute key =~ "#"
    end

    test "generates unique keys for the same filename" do
      refute S3Uploader.build_key("contract.pdf") == S3Uploader.build_key("contract.pdf")
    end
  end

  describe "public_url/2" do
    test "returns the canonical S3 object URL" do
      assert S3Uploader.public_url("test-bucket", "uploads/cms_images/abc/file.pdf") ==
               "https://test-bucket.s3.amazonaws.com/uploads/cms_images/abc/file.pdf"
    end
  end

  describe "bucket/0" do
    test "returns the configured bucket" do
      assert S3Uploader.bucket() == "test-bucket"
    end
  end

  describe "generate_presigned_url/2" do
    test "generates a presigned PUT URL and canonical object URL" do
      assert {:ok, upload_url, object_url, key} = S3Uploader.generate_presigned_url("contract.pdf", "application/pdf")

      assert String.starts_with?(key, "uploads/cms_images/")
      assert String.ends_with?(key, "/contract.pdf")
      assert object_url == "https://test-bucket.s3.amazonaws.com/#{key}"

      uri = URI.parse(upload_url)
      assert uri.scheme == "https"
      assert uri.host == "s3.amazonaws.com"
      assert uri.path =~ "/test-bucket/#{key}"
      assert uri.query =~ "X-Amz-"
    end
  end

  describe "generate_presigned_download_url_for_key/2" do
    test "generates a presigned GET URL" do
      key = "uploads/cms_images/abc/contract.pdf"

      assert {:ok, url} = S3Uploader.generate_presigned_download_url_for_key(key)

      uri = URI.parse(url)
      assert uri.scheme == "https"
      assert uri.host == "s3.amazonaws.com"
      assert uri.path =~ "/test-bucket/uploads/cms_images/abc/contract.pdf"
      assert uri.query =~ "X-Amz-"
    end

    test "accepts a custom expiration" do
      assert {:ok, url} = S3Uploader.generate_presigned_download_url_for_key("uploads/cms_images/abc/contract.pdf", expires_in: 300)

      assert URI.decode_query(URI.parse(url).query)["X-Amz-Expires"] == "300"
    end
  end

  describe "generate_presigned_download_url/2" do
    test "generates a signed URL from a stored object URL" do
      object_url = "https://test-bucket.s3.amazonaws.com/uploads/cms_images/abc/contract.pdf"

      assert {:ok, signed_url} = S3Uploader.generate_presigned_download_url(object_url)

      uri = URI.parse(signed_url)
      assert uri.path =~ "/uploads/cms_images/abc/contract.pdf"
      assert uri.query =~ "X-Amz-"
    end

    test "rejects a URL outside the configured bucket" do
      assert {:error, :invalid_s3_url} =
               S3Uploader.generate_presigned_download_url("https://some-other-bucket.s3.amazonaws.com/uploads/file.pdf")
    end

    test "rejects nil" do
      assert {:error, :invalid_s3_url} = S3Uploader.generate_presigned_download_url(nil)
    end
  end
end
