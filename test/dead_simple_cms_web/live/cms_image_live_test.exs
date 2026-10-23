defmodule DeadSimpleCmsWeb.CmsImageLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase

  import Phoenix.LiveViewTest
  import DeadSimpleCms.Factory

  alias DeadSimpleCms.Cms.CmsImage
  alias DeadSimpleCms.Repo

  setup :base_data

  describe "Index" do
    test "lists images with thumbnail, description and where they're used", %{conn: conn, data: data} do
      {:ok, index_live, html} = live(conn, ~p"/cms_images")

      assert html =~ "Images"
      refute html =~ "Listing CMS Images"
      assert html =~ data.cms_image.filename
      assert html =~ data.cms_image.alt
      assert has_element?(index_live, "#cms_images-#{data.cms_image.id} img[src='#{data.cms_image.url}']")
      # The base data uses the image in one section and one bio.
      assert has_element?(index_live, "#cms_images-#{data.cms_image.id}", "Used in 2 places")
    end

    test "flags images with no description and placeholder captions", %{conn: conn} do
      bare = insert(:cms_image, alt: nil, caption: "PLACEHOLDER: replace with a crew photo")

      {:ok, index_live, _html} = live(conn, ~p"/cms_images")

      assert has_element?(index_live, "#cms_images-#{bare.id}", "Needs a description")
      assert has_element?(index_live, "#cms_images-#{bare.id}", "Placeholder")
      assert has_element?(index_live, "#cms_images-#{bare.id}", "Not used anywhere")
    end

    test "shows an empty state with no images", %{conn: conn} do
      Repo.delete_all(CmsImage)

      {:ok, _index_live, html} = live(conn, ~p"/cms_images")

      assert html =~ "No images yet"
    end

    test "clicking a row opens the image", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_images")

      assert {:ok, _show_live, html} =
               index_live
               |> element("#cms_images-#{data.cms_image.id} td:first-child")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_images/#{data.cms_image}")

      assert html =~ "Used on"
    end

    test "adds a new image", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_images")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Add image")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_images/new")

      assert render(form_live) =~ "Add image"

      assert form_live
             |> form("#cms_image-form", cms_image: %{alt: "some new alt", url: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_image-form", cms_image: %{alt: "some new alt", url: "https://example.com", filename: "somefilename", content_type: "img/jpeg", size: 12})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_images")

      html = render(index_live)
      assert html =~ "Image added"
      assert html =~ "somefilename"
    end

    test "edits an image from the listing", %{conn: conn, data: data} do
      # Rows open the image; it has the Edit image button.
      {:ok, form_live, _html} = live(conn, ~p"/cms_images/#{data.cms_image}/edit")

      assert render(form_live) =~ "Edit image"

      assert form_live
             |> form("#cms_image-form", cms_image: %{alt: "some new alt", url: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_image-form", cms_image: %{alt: "some updated alt", filename: "some updated filename", url: "https://example.com"})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_images")

      html = render(index_live)
      assert html =~ "Image saved"
      assert html =~ "some updated filename"
    end

    test "delete confirmation names every place the image is used", %{conn: conn, data: data} do
      insert(:cms_page, title: "Contact", og_image_id: data.cms_image.id)

      {:ok, index_live, _html} = live(conn, ~p"/cms_images")

      confirm = index_live |> element("#cms_images-#{data.cms_image.id} a", "Delete") |> render() |> confirm_text()

      assert confirm =~ "Delete the image \"#{data.cms_image.filename}\"?"
      assert confirm =~ "Used in 3 places:"
      assert confirm =~ "#{data.cms_page.title} (#{data.cms_content_area.title})"
      assert confirm =~ "#{data.cms_bio.name} (bio)"
      assert confirm =~ "Contact (share image)"
      assert confirm =~ "They'll be left without an image."
    end

    test "delete confirmation says when an image isn't used", %{conn: conn} do
      unused = insert(:cms_image)

      {:ok, index_live, _html} = live(conn, ~p"/cms_images")

      confirm = index_live |> element("#cms_images-#{unused.id} a", "Delete") |> render() |> confirm_text()
      assert confirm =~ "Not used anywhere"
    end

    test "deletes an image and says so", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_images")

      html = index_live |> element("#cms_images-#{data.cms_image.id} a", "Delete") |> render_click()

      assert html =~ "Image &quot;#{data.cms_image.filename}&quot; deleted"
      refute has_element?(index_live, "#cms_images-#{data.cms_image.id}")
      assert Repo.reload(data.cms_content_area).cms_image_id == nil
    end
  end

  describe "Show" do
    test "shows the image large with its details and where it's used", %{conn: conn, data: data} do
      insert(:cms_page, title: "Contact", og_image_id: data.cms_image.id)
      template_area = insert(:cms_content_area, cms_page_template_id: data.cms_page_template.id, cms_image_id: data.cms_image.id, title: "Hero")

      {:ok, show_live, html} = live(conn, ~p"/cms_images/#{data.cms_image}")

      assert has_element?(show_live, "#cms-image-preview[src='#{data.cms_image.url}']")
      assert html =~ data.cms_image.alt
      assert html =~ data.cms_image.caption
      assert html =~ "1200 × 800 pixels"
      assert html =~ "JPEG · 1.2 MB"
      assert html =~ "Uploaded"

      assert has_element?(show_live, "#image-usage a[href='/cms_pages/#{data.cms_page.id}/edit']", "Edit page")
      assert has_element?(show_live, "#image-usage a[href='/cms_page_templates/#{data.cms_page_template.id}/edit']", "Edit template")
      assert has_element?(show_live, "#image-usage a[href='/cms_bios/#{data.cms_bio.id}']", "Open bio")
      assert has_element?(show_live, "#image-usage", "Share image for search and social")
      assert has_element?(show_live, "#image-usage", "Section: #{template_area.title}")
    end

    test "flags a missing description and a placeholder caption", %{conn: conn} do
      image = insert(:cms_image, alt: "", caption: "Placeholder until we shoot the salon")

      {:ok, _show_live, html} = live(conn, ~p"/cms_images/#{image}")

      assert html =~ "Needs a description"
      assert html =~ "Placeholder image"
      assert html =~ "Not used anywhere yet"
    end

    test "edits the image and returns to it", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_images/#{data.cms_image}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit image")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_images/#{data.cms_image}/edit?return_to=show")

      assert render(form_live) =~ "Edit image"

      assert form_live
             |> form("#cms_image-form", cms_image: %{alt: "some updated alt", url: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#cms_image-form", cms_image: %{alt: "some updated alt", url: "https://example.com"})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_images/#{data.cms_image}")

      html = render(show_live)
      assert html =~ "Image saved"
      assert html =~ "some updated alt"
    end

    test "deletes the image after a confirmation that lists where it's used", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_images/#{data.cms_image}")

      confirm = show_live |> element("#delete-cms-image") |> render() |> confirm_text()
      assert confirm =~ "Used in 2 places:"

      assert {:ok, _index_live, html} = show_live |> element("#delete-cms-image") |> render_click() |> follow_redirect(conn, ~p"/cms_images")

      assert html =~ "Image &quot;#{data.cms_image.filename}&quot; deleted"
      refute Repo.get(CmsImage, data.cms_image.id)
    end
  end

  describe "Form" do
    test "uses plain labels and guidance", %{conn: conn, data: data} do
      {:ok, _form_live, html} = live(conn, ~p"/cms_images/#{data.cms_image}/edit")

      assert html =~ "Description (alt text)"
      assert html =~ "one plain sentence"
      assert html =~ "Placeholder"
      assert html =~ "Image URL"
      assert html =~ "File type"
      assert html =~ "File size (bytes)"
      assert html =~ "JPG, PNG, GIF, WEBP or AVIF"
      assert html =~ "1.2 MB"
      refute html =~ "Content-Type:"
    end

    test "deletes the image from the edit screen", %{conn: conn, data: data} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_images/#{data.cms_image}/edit")

      assert form_live |> element("#delete-cms-image") |> render() |> confirm_text() =~ "#{data.cms_bio.name} (bio)"

      assert {:ok, _index_live, html} = form_live |> element("#delete-cms-image") |> render_click() |> follow_redirect(conn, ~p"/cms_images")
      assert html =~ "deleted"
    end

    test "has no delete button when adding an image", %{conn: conn} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_images/new")

      refute has_element?(form_live, "#delete-cms-image")
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

    test "uploading a file on an existing image replaces it and keeps the description", %{conn: conn, data: data} do
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

      assert html =~ "Image added"
      assert %{filename: "marina.png", content_type: "image/png", caption: "Our home dock"} = Repo.get_by!(CmsImage, filename: "marina.png")
    end

    test "rejects a file type the site can't show", %{conn: conn} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_images/new")

      image = file_input(form_live, "#cms_image-form", :image, [%{name: "scan.tiff", content: "tiff bytes", type: "image/tiff"}])

      assert {:error, [[_ref, :not_accepted]]} = render_upload(image, "scan.tiff")
    end
  end

  # The decoded data-confirm text of a rendered element.
  defp confirm_text(html) do
    [confirm] = html |> LazyHTML.from_fragment() |> LazyHTML.attribute("data-confirm")
    confirm
  end
end
