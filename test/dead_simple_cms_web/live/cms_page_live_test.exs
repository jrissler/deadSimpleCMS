defmodule DeadSimpleCmsWeb.CmsPageLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :base_data

  describe "Index" do
    test "lists all cms_pages", %{conn: conn, data: data} do
      {:ok, _index_live, html} = live(conn, ~p"/cms_pages")

      assert html =~ "Listing CMS Pages"
      assert html =~ data.cms_page.title
    end

    test "saves new cms_page", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_pages")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Add CMS Page")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_pages/new")

      assert render(form_live) =~ "New CMS Page"

      assert form_live
             |> form("#cms_page-form", cms_page: params_for(:cms_page, slug: "some slug", title: "", cms_page_template_id: data.cms_page_template.id))
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_page-form", cms_page: params_for(:cms_page, slug: "some slug", title: "some new title", cms_page_template_id: data.cms_page_template.id))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_pages")

      html = render(index_live)
      assert html =~ "Cms page created successfully"
      assert html =~ "some new title"
    end

    test "updates cms_page in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_pages")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#cms_pages-#{data.cms_page.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      assert render(form_live) =~ "Edit CMS Page"

      assert form_live
             |> form("#cms_page-form", cms_page: params_for(:cms_page, title: "", cms_page_template_id: data.cms_page_template.id))
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_page-form", cms_page: params_for(:cms_page, title: "some updated title", cms_page_template_id: data.cms_page_template.id))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_pages")

      html = render(index_live)
      assert html =~ "Cms page updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes cms_page in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_pages")

      assert index_live |> element("#cms_pages-#{data.cms_page.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#cms_pages-#{data.cms_page.id}")
    end
  end

  describe "Show" do
    test "displays cms_page", %{conn: conn, data: data} do
      {:ok, _show_live, html} = live(conn, ~p"/cms_pages/#{data.cms_page}")

      assert html =~ "Viewing CMS Page"
      assert html =~ data.cms_page.title
    end

    test "has no Preview Page button unless the host sets page_preview_url", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}")
      refute has_element?(show_live, "#cms-page-preview")

      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")
      refute has_element?(form_live, "#cms-page-preview")
    end

    test "links the show and edit screens to the host's preview, in a new tab", %{conn: conn, data: data} do
      Application.put_env(:dead_simple_cms, :page_preview_url, "/preview/:slug")
      on_exit(fn -> Application.delete_env(:dead_simple_cms, :page_preview_url) end)

      {:ok, show_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}")
      assert has_element?(show_live, "#cms-page-preview[href='/preview/#{data.cms_page.slug}'][target='_blank']", "Preview Page")

      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")
      assert has_element?(form_live, "#cms-page-preview[href='/preview/#{data.cms_page.slug}']")

      {:ok, new_live, _html} = live(conn, ~p"/cms_pages/new")
      refute has_element?(new_live, "#cms-page-preview")
    end

    test "updates SEO fields from the edit form", %{conn: conn, data: data} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit?return_to=show")

      assert form_live
             |> form("#cms_page-form", cms_page: %{meta_description: String.duplicate("a", 321)})
             |> render_change() =~ "should be at most 320 character(s)"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#cms_page-form", cms_page: %{meta_title: "Yacht Charter Marketing", meta_description: "Marketing for charter operators.", og_image_id: data.cms_image.id, noindex: true})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_pages/#{data.cms_page}")

      html = render(show_live)
      assert html =~ "Yacht Charter Marketing"
      assert html =~ "Marketing for charter operators."
      assert html =~ data.cms_image.url
    end

    test "updates cms_page and returns to show", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_pages/#{data.cms_page}/edit?return_to=show")

      assert render(form_live) =~ "Edit CMS Page"

      assert form_live
             |> form("#cms_page-form", cms_page: params_for(:cms_page, title: "", cms_page_template_id: data.cms_page_template.id))
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#cms_page-form", cms_page: params_for(:cms_page, title: "some updated title", cms_page_template_id: data.cms_page_template.id))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_pages/#{data.cms_page}")

      html = render(show_live)
      assert html =~ "Cms page updated successfully"
      assert html =~ "some updated title"
    end
  end

  describe "Edit content area images" do
    setup %{data: data} do
      original_s3 = Application.get_env(:dead_simple_cms, :s3)
      Application.put_env(:dead_simple_cms, :s3, bucket: "test-bucket", region: "us-east-1", access_key_id: "test-key", secret_access_key: "test-secret")

      on_exit(fn ->
        if original_s3,
          do: Application.put_env(:dead_simple_cms, :s3, original_s3),
          else: Application.delete_env(:dead_simple_cms, :s3)
      end)

      {:ok, image} = DeadSimpleCms.Cms.update_cms_image(data.cms_image, %{caption: "Placeholder: replace with a charter photo"})
      %{data: %{data | cms_image: image}}
    end

    test "shows each area's current image and caption", %{conn: conn, data: data} do
      {:ok, _form_live, html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      assert html =~ data.cms_image.url
      assert html =~ "Placeholder: replace with a charter photo"
      assert html =~ "Replace image"
    end

    test "uploading replaces the image on that area only", %{conn: conn, data: data} do
      other_area = insert(:cms_content_area, cms_page_id: data.cms_page.id, cms_image_id: data.cms_image.id, cms_slot_id: data.cms_slot.id)
      area = data.cms_content_area

      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      upload = file_input(form_live, "#content-area-form-#{area.id}", String.to_atom("area_image_" <> area.id), [%{name: "sunset.jpg", content: "jpeg bytes", type: "image/jpeg"}])
      assert render_upload(upload, "sunset.jpg") =~ "sunset.jpg"

      html = form_live |> form("#content-area-form-#{area.id}") |> render_submit()
      assert html =~ "Content area saved"

      updated = DeadSimpleCms.Cms.get_cms_content_area!(area.id)
      assert updated.cms_image.filename == "sunset.jpg"
      assert updated.cms_image.url =~ ~r{^https://test-bucket\.s3\.amazonaws\.com/uploads/cms_images/.+/sunset\.jpg$}
      assert html =~ updated.cms_image.url

      assert DeadSimpleCms.Cms.get_cms_content_area!(other_area.id).cms_image_id == data.cms_image.id
      assert DeadSimpleCms.Cms.get_cms_image!(data.cms_image.id).filename == data.cms_image.filename
    end

    test "removes an area's image", %{conn: conn, data: data} do
      area = data.cms_content_area
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      html = form_live |> element("#content-area-#{area.id}-image button", "Remove image") |> render_click()

      assert html =~ "Image removed"
      assert DeadSimpleCms.Cms.get_cms_content_area!(area.id).cms_image_id == nil
      assert has_element?(form_live, "#content-area-#{area.id}-image", "No image")
    end
  end

  describe "Templates and slot help" do
    test "a page created from a template starts with the template's sections", %{conn: conn, data: data} do
      insert(:cms_content_area, cms_page_template_id: data.cms_page_template.id, cms_slot_id: data.cms_slot.id, name: "hero", position: 0, title: "Starter hero")
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/new")

      assert has_element?(form_live, "#cms_page-form", "starts with a copy of the template's sections")

      {:ok, _index, html} =
        form_live
        |> form("#cms_page-form", cms_page: params_for(:cms_page, slug: "from-template", title: "From template", cms_page_template_id: data.cms_page_template.id))
        |> render_submit()
        |> follow_redirect(conn, ~p"/cms_pages")

      assert html =~ "Cms page created successfully"
      page = DeadSimpleCms.Cms.get_preview_page_by_slug("from-template")
      assert Enum.map(page.cms_content_areas, & &1.title) == ["Starter hero"]
    end

    test "each section shows its slot's description as help text", %{conn: conn, data: data} do
      {:ok, _} = DeadSimpleCms.Cms.update_cms_slot(data.cms_slot, %{description: "One fact per line: 15,000+ | nautical miles"})
      area = data.cms_content_area
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      assert has_element?(form_live, "#content-area-#{area.id}-slot-help", "One fact per line")
    end
  end

  describe "Edit navigation" do
    test "content areas start collapsed with a summary row each", %{conn: conn, data: data} do
      area = data.cms_content_area
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      assert has_element?(form_live, "details#content-area-#{area.id}:not([open])")
      assert has_element?(form_live, "#content-area-#{area.id}-summary", area.name)
      assert has_element?(form_live, "#content-area-#{area.id}-summary", data.cms_slot.name)
      assert has_element?(form_live, "#content-area-#{area.id}-summary", area.title)
    end

    test "the outline lists page settings, SEO and every content area", %{conn: conn, data: data} do
      second = insert(:cms_content_area, cms_page_id: data.cms_page.id, cms_slot_id: data.cms_slot.id, name: "faq")
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      assert has_element?(form_live, "#cms-page-outline button", "Page settings")
      assert has_element?(form_live, "#cms-page-outline button", "SEO")
      assert has_element?(form_live, "#outline-#{data.cms_content_area.id}", data.cms_content_area.name)
      assert has_element?(form_live, "#outline-#{second.id}", "faq")
    end

    test "an edited area is marked unsaved until it's saved", %{conn: conn, data: data} do
      area = data.cms_content_area
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      refute has_element?(form_live, "#content-area-#{area.id}-summary", "Unsaved")

      form_live |> form("#content-area-form-#{area.id}", cms_content_area: %{title: "A new title"}) |> render_change()
      assert has_element?(form_live, "#content-area-#{area.id}-summary", "Unsaved")
      assert has_element?(form_live, "#outline-#{area.id} [title='Unsaved changes']")

      form_live |> form("#content-area-form-#{area.id}", cms_content_area: %{title: "A new title"}) |> render_submit()
      refute has_element?(form_live, "#content-area-#{area.id}-summary", "Unsaved")
      assert has_element?(form_live, "#content-area-#{area.id}-summary", "A new title")
    end

    test "a newly added area opens", %{conn: conn, data: data} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      form_live |> element("button", "Add Content Area") |> render_click()

      new_area = DeadSimpleCms.Repo.get_by!(DeadSimpleCms.Cms.CmsContentArea, cms_page_id: data.cms_page.id, name: "New Content Area")
      assert has_element?(form_live, "details#content-area-#{new_area.id}[open]")
      assert has_element?(form_live, "details#content-area-#{data.cms_content_area.id}:not([open])")
    end
  end
end
