defmodule DeadSimpleCms.ImageUrlTest do
  # Changes application env, so not async.
  use ExUnit.Case, async: false

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsImage
  alias DeadSimpleCms.Cms.CmsPage
  alias DeadSimpleCmsWeb.ImageUploads

  @url "https://test-bucket.s3.amazonaws.com/uploads/cms_images/abc/hero.jpg"

  setup do
    original_s3 = Application.get_env(:dead_simple_cms, :s3)
    original_image_urls = Application.get_env(:dead_simple_cms, :image_urls)

    Application.put_env(:dead_simple_cms, :s3, region: "us-east-1", access_key_id: "test-access-key", secret_access_key: "test-secret-key", bucket: "test-bucket")

    on_exit(fn ->
      restore(:s3, original_s3)
      restore(:image_urls, original_image_urls)
    end)

    %{image: %CmsImage{url: @url, alt: "Hero"}}
  end

  defp restore(key, nil), do: Application.delete_env(:dead_simple_cms, key)
  defp restore(key, value), do: Application.put_env(:dead_simple_cms, key, value)

  test "image_url/1 is the stored url by default", %{image: image} do
    assert Cms.image_url(image) == @url
    assert Cms.image_url(nil) == nil
  end

  describe "with image_urls: :signed" do
    setup do
      Application.put_env(:dead_simple_cms, :image_urls, :signed)
    end

    test "image_url/1 is a presigned GET url", %{image: image} do
      uri = URI.parse(Cms.image_url(image))

      assert uri.path =~ "/test-bucket/uploads/cms_images/abc/hero.jpg"
      assert uri.query =~ "X-Amz-Signature="
    end

    test "image_url/1 leaves a url outside the bucket as stored" do
      assert Cms.image_url(%CmsImage{url: "https://example.com/hero.jpg"}) == "https://example.com/hero.jpg"
    end

    test "page_seo/1 signs the og image", %{image: image} do
      seo = Cms.page_seo(%CmsPage{title: "Page", og_image: image})

      assert seo.og_image_url =~ "X-Amz-Signature="
      assert seo.og_image_alt == "Hero"
    end

    test "uploads aren't made public-read" do
      assert {:ok, meta, :socket} = ImageUploads.presign_upload(%{client_name: "hero.jpg", client_type: "image/jpeg"}, :socket)
      assert meta.headers == %{"content-type" => "image/jpeg"}
    end
  end

  test "public uploads are made public-read" do
    assert {:ok, meta, :socket} = ImageUploads.presign_upload(%{client_name: "hero.jpg", client_type: "image/jpeg"}, :socket)
    assert meta.headers["x-amz-acl"] == "public-read"
  end
end
