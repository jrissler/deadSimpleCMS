defmodule DeadSimpleCmsWeb.CmsImageLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :base_data

  describe "Index" do
    test "lists all cms_images", %{conn: conn, data: data} do
      {:ok, _index_live, html} = live(conn, ~p"/cms_images")

      assert html =~ "Listing CMS Images"
      assert html =~ data.cms_image.filename
    end

    test "saves new cms_image", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_images")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Add CMS Image")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_images/new")

      assert render(form_live) =~ "New Cms image"

      assert form_live
             |> form("#cms_image-form", cms_image: %{alt: "some new alt", url: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_image-form", cms_image: %{alt: "some new alt", url: "https://example.com", filename: "somefilename", content_type: "img/jpeg", size: 12})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_images")

      html = render(index_live)
      assert html =~ "Cms image created successfully"
      assert html =~ "somefilename"
    end

    test "updates cms_image in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_images")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#cms_images-#{data.cms_image.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_images/#{data.cms_image}/edit")

      assert render(form_live) =~ "Edit Cms image"

      assert form_live
             |> form("#cms_image-form", cms_image: %{alt: "some new alt", url: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_image-form", cms_image: %{alt: "some updated alt", filename: "some updated filename", url: "https://example.com"})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_images")

      html = render(index_live)
      assert html =~ "Cms image updated successfully"
      assert html =~ "some updated filename"
    end

    test "deletes cms_image in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_images")

      assert index_live |> element("#cms_images-#{data.cms_image.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#cms_images-#{data.cms_image.id}")
    end
  end

  describe "Show" do
    test "displays cms_image", %{conn: conn, data: data} do
      {:ok, _show_live, html} = live(conn, ~p"/cms_images/#{data.cms_image}")

      assert html =~ "Viewing CMS Image"
      assert html =~ data.cms_image.alt
    end

    test "updates cms_image and returns to show", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_images/#{data.cms_image}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_images/#{data.cms_image}/edit?return_to=show")

      assert render(form_live) =~ "Edit Cms image"

      assert form_live
             |> form("#cms_image-form", cms_image: %{alt: "some updated alt", url: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#cms_image-form", cms_image: %{alt: "some updated alt", url: "https://example.com"})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_images/#{data.cms_image}")

      html = render(show_live)
      assert html =~ "Cms image updated successfully"
      assert html =~ "some updated alt"
    end
  end

  describe "Upload" do
    setup do
      original_s3 = Application.get_env(:dead_simple_cms, :s3)
      Application.put_env(:dead_simple_cms, :s3, bucket: "test-bucket", region: "us-east-1", access_key_id: "test-key", secret_access_key: "test-secret")

      on_exit(fn ->
        if original_s3,
          do: Application.put_env(:dead_simple_cms, :s3, original_s3),
          else: Application.delete_env(:dead_simple_cms, :s3)
      end)

      :ok
    end

    test "uploading a file on an existing image replaces it and keeps the alt text", %{conn: conn, data: data} do
      {:ok, form_live, html} = live(conn, ~p"/cms_images/#{data.cms_image}/edit")

      assert html =~ "Upload a new file to replace this image everywhere it&#39;s used."
      assert html =~ data.cms_image.url

      image = file_input(form_live, "#cms_image-form", :image, [%{name: "sunset-cruise.jpg", content: "fake image bytes", type: "image/jpeg"}])
      assert render_upload(image, "sunset-cruise.jpg") =~ "sunset-cruise.jpg"

      assert {:ok, _show_live, _html} =
               form_live
               |> form("#cms_image-form", cms_image: %{alt: "Guests on the sunset cruise"})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_images")

      image = DeadSimpleCms.Cms.get_cms_image!(data.cms_image.id)
      assert image.filename == "sunset-cruise.jpg"
      assert image.content_type == "image/jpeg"
      assert image.size == byte_size("fake image bytes")
      assert image.url =~ ~r{^https://test-bucket\.s3\.amazonaws\.com/uploads/cms_images/.+/sunset-cruise\.jpg$}
      assert image.alt == "Guests on the sunset cruise"
    end

    test "creates a new image from an upload without the manual fields", %{conn: conn} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_images/new")

      image = file_input(form_live, "#cms_image-form", :image, [%{name: "marina.png", content: "png bytes", type: "image/png"}])
      render_upload(image, "marina.png")

      refute form_live |> form("#cms_image-form", cms_image: %{alt: "The marina"}) |> render_change() =~ "can&#39;t be blank"

      assert {:ok, _index_live, html} =
               form_live
               |> form("#cms_image-form", cms_image: %{alt: "The marina", caption: "Our home dock"})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_images")

      assert html =~ "Cms image created successfully"
      assert %{filename: "marina.png", content_type: "image/png", caption: "Our home dock"} = DeadSimpleCms.Repo.get_by!(DeadSimpleCms.Cms.CmsImage, filename: "marina.png")
    end
  end
end
