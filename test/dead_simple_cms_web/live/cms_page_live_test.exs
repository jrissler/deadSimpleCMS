defmodule DeadSimpleCmsWeb.CmsPageLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase

  import Phoenix.LiveViewTest

  alias DeadSimpleCms.Cms

  setup :base_data

  describe "Index" do
    test "lists pages with their status, template and section count", %{conn: conn, data: data} do
      draft = insert(:cms_page, title: "Draft page", published: false)
      {:ok, index_live, html} = live(conn, ~p"/cms_pages")

      assert html =~ "Pages"
      assert has_element?(index_live, "#cms_pages-#{data.cms_page.id}", data.cms_page.title)
      assert has_element?(index_live, "#cms_pages-#{data.cms_page.id}", "Live")
      assert has_element?(index_live, "#cms_pages-#{data.cms_page.id}", data.cms_page_template.name)
      assert has_element?(index_live, "#cms_pages-#{draft.id}", "Draft")
      refute html =~ ">true<"
    end

    test "shows a friendly message when there are no pages", %{conn: conn, data: data} do
      Cms.delete_cms_page(data.cms_page)
      {:ok, index_live, _html} = live(conn, ~p"/cms_pages")

      assert has_element?(index_live, "#cms_pages-empty", "No pages yet")
    end

    test "creates a page, filling in its address from the title, and opens its editor", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_pages")

      assert {:ok, form_live, _} = index_live |> element("a", "New page") |> render_click() |> follow_redirect(conn, ~p"/cms_pages/new")
      assert render(form_live) =~ "New page"
      assert form_live |> form("#cms_page-form", cms_page: %{title: ""}) |> render_change() =~ "can&#39;t be blank"

      {:ok, edit_live, html} = form_live |> form("#cms_page-form", cms_page: %{title: "Who We Are"}) |> render_submit() |> follow_redirect(conn)

      page = Cms.get_preview_page_by_slug("who-we-are")
      assert page.title == "Who We Are"
      assert html =~ "Page created"
      assert has_element?(edit_live, "#content-areas-empty", "No sections yet")
    end

    test "editing a page from the listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_pages")

      assert {:ok, _form_live, html} = index_live |> element("#cms_pages-#{data.cms_page.id} a", "Edit") |> render_click() |> follow_redirect(conn, ~p"/cms_pages/#{data.cms_page}/edit")
      assert html =~ "Edit page"
    end

    test "deletes a page, naming it in the confirmation", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_pages")

      assert has_element?(index_live, "#cms_pages-#{data.cms_page.id} a[data-confirm*='#{data.cms_page.title}']", "Delete")
      html = index_live |> element("#cms_pages-#{data.cms_page.id} a", "Delete") |> render_click()

      assert html =~ "deleted"
      refute has_element?(index_live, "#cms_pages-#{data.cms_page.id}")
    end
  end

  describe "Show" do
    test "summarizes the page and its sections", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}")

      assert has_element?(show_live, "#page-sections", data.cms_content_area.title)
      assert has_element?(show_live, "a", "Edit page")
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
  end

  describe "Edit page settings" do
    test "saving keeps you on the page, with unsaved section edits intact", %{conn: conn, data: data} do
      area = data.cms_content_area
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      form_live |> form("#content-area-form-#{area.id}", cms_content_area: %{title: "Typed but not saved"}) |> render_change()
      html = form_live |> form("#cms_page-form", cms_page: %{title: "Renamed"}) |> render_submit()

      assert html =~ "Page settings saved"
      assert Cms.get_cms_page!(data.cms_page.id).title == "Renamed"
      assert has_element?(form_live, "#content-area-#{area.id}-summary", "Unsaved")
    end

    test "updates search and sharing fields", %{conn: conn, data: data} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      assert form_live |> form("#cms_page-form", cms_page: %{meta_description: String.duplicate("a", 321)}) |> render_change() =~ "should be at most 320 character(s)"

      form_live
      |> form("#cms_page-form", cms_page: %{meta_title: "Yacht Charter Marketing", meta_description: "Marketing for charter operators.", og_image_id: data.cms_image.id, noindex: true})
      |> render_submit()

      page = Cms.get_cms_page!(data.cms_page.id)
      assert page.meta_title == "Yacht Charter Marketing"
      assert page.og_image_id == data.cms_image.id
      assert page.noindex
    end

    test "publishing without a date sets today's", %{conn: conn} do
      draft = insert(:cms_page, published: false, published_at: nil)
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{draft}/edit")

      form_live |> form("#cms_page-form", cms_page: %{published: true}) |> render_submit()

      page = Cms.get_cms_page!(draft.id)
      assert page.published
      assert DateTime.to_date(page.published_at) == Date.utc_today()
    end

    test "deletes the page from its editor", %{conn: conn, data: data} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      assert {:ok, _index, html} = form_live |> element("#delete-cms-page") |> render_click() |> follow_redirect(conn, ~p"/cms_pages")
      assert html =~ "deleted"
      assert_raise Ecto.NoResultsError, fn -> Cms.get_cms_page!(data.cms_page.id) end
    end
  end

  describe "Sections" do
    setup %{data: data} do
      original_s3 = Application.get_env(:dead_simple_cms, :s3)
      Application.put_env(:dead_simple_cms, :s3, bucket: "test-bucket", region: "us-east-1", access_key_id: "test-key", secret_access_key: "test-secret")

      on_exit(fn ->
        if original_s3,
          do: Application.put_env(:dead_simple_cms, :s3, original_s3),
          else: Application.delete_env(:dead_simple_cms, :s3)
      end)

      {:ok, image} = Cms.update_cms_image(data.cms_image, %{caption: "Placeholder: replace with a charter photo"})
      %{data: %{data | cms_image: image}}
    end

    test "start collapsed, with a summary row each and a placeholder flag", %{conn: conn, data: data} do
      area = data.cms_content_area
      {:ok, form_live, html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      assert has_element?(form_live, "details#content-area-#{area.id}:not([open])")
      assert has_element?(form_live, "#content-area-#{area.id}-summary", area.title)
      assert has_element?(form_live, "#content-area-#{area.id}-summary", data.cms_slot.name)
      assert has_element?(form_live, "#content-area-#{area.id}-summary", "Placeholder image")
      assert html =~ "Placeholder: replace with a charter photo"
    end

    test "show their section type's description as help text", %{conn: conn, data: data} do
      {:ok, _} = Cms.update_cms_slot(data.cms_slot, %{description: "One fact per line: 15,000+ | nautical miles"})
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      assert has_element?(form_live, "#content-area-#{data.cms_content_area.id}-slot-help", "One fact per line")
    end

    test "are marked unsaved until saved", %{conn: conn, data: data} do
      area = data.cms_content_area
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      refute has_element?(form_live, "#content-area-#{area.id}-summary", "Unsaved")
      form_live |> form("#content-area-form-#{area.id}", cms_content_area: %{title: "A new title"}) |> render_change()
      assert has_element?(form_live, "#content-area-#{area.id}-summary", "Unsaved")

      form_live |> form("#content-area-form-#{area.id}", cms_content_area: %{title: "A new title"}) |> render_submit()
      assert render(form_live) =~ "Section saved"
      refute has_element?(form_live, "#content-area-#{area.id}-summary", "Unsaved")
      assert has_element?(form_live, "#content-area-#{area.id}-summary", "A new title")
    end

    test "a new section opens and gets a unique name", %{conn: conn, data: data} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      form_live |> element("#content-areas-add") |> render_click()

      new_area = DeadSimpleCms.Repo.get_by!(DeadSimpleCms.Cms.CmsContentArea, cms_page_id: data.cms_page.id, name: "section-2")
      assert has_element?(form_live, "details#content-area-#{new_area.id}[open]")
      assert has_element?(form_live, "details#content-area-#{data.cms_content_area.id}:not([open])")
    end

    test "move up and down, with no raw position field", %{conn: conn, data: data} do
      first = data.cms_content_area
      second = insert(:cms_content_area, cms_page_id: data.cms_page.id, cms_slot_id: data.cms_slot.id, name: "second", title: "Second")
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      refute has_element?(form_live, "#content-area-#{first.id}-move-up")
      refute has_element?(form_live, "input[name='cms_content_area[position]']")

      form_live |> element("#content-area-#{second.id}-move-up") |> render_click()

      assert Enum.map(Cms.list_owner_content_areas({:page, data.cms_page.id}), & &1.id) == [second.id, first.id]
      assert has_element?(form_live, "#content-area-#{first.id}-move-up")
    end

    test "delete with a confirmation naming the section", %{conn: conn, data: data} do
      area = data.cms_content_area
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      assert has_element?(form_live, "#content-area-#{area.id}-delete[data-confirm*='#{area.title}']")
      form_live |> element("#content-area-#{area.id}-delete") |> render_click()
      assert render(form_live) =~ "Section deleted"
      refute has_element?(form_live, "#content-area-#{area.id}")
    end

    test "uploading replaces the image on that section only, with its description", %{conn: conn, data: data} do
      other_area = insert(:cms_content_area, cms_page_id: data.cms_page.id, cms_image_id: data.cms_image.id, cms_slot_id: data.cms_slot.id)
      area = data.cms_content_area
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      upload = file_input(form_live, "#content-area-form-#{area.id}", String.to_atom("area_image_" <> area.id), [%{name: "sunset.jpg", content: "jpeg bytes", type: "image/jpeg"}])
      assert render_upload(upload, "sunset.jpg") =~ "sunset.jpg"

      form_live |> form("#content-area-form-#{area.id}", image_alt: "Empire at sunset") |> render_submit()
      assert render(form_live) =~ "Section saved"

      updated = Cms.get_cms_content_area!(area.id)
      assert updated.cms_image.filename == "sunset.jpg"
      assert updated.cms_image.alt == "Empire at sunset"
      assert updated.cms_image.url =~ ~r{^https://test-bucket\.s3\.amazonaws\.com/uploads/cms_images/.+/sunset\.jpg$}
      assert Cms.get_cms_content_area!(other_area.id).cms_image_id == data.cms_image.id
    end

    test "editing the description updates the section's existing image", %{conn: conn, data: data} do
      area = data.cms_content_area
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      form_live |> form("#content-area-form-#{area.id}", image_alt: "A better description") |> render_submit()

      assert Cms.get_cms_image!(data.cms_image.id).alt == "A better description"
    end

    test "removing an image keeps it in the library", %{conn: conn, data: data} do
      area = data.cms_content_area
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}/edit")

      form_live |> element("#content-area-#{area.id}-image button", "Remove image") |> render_click()
      assert render(form_live) =~ "Image removed"
      assert Cms.get_cms_content_area!(area.id).cms_image_id == nil
      assert Cms.get_cms_image!(data.cms_image.id)
      assert has_element?(form_live, "#content-area-#{area.id}-image", "No image")
    end
  end

  describe "Templates" do
    test "a page created from a template starts with the template's starter sections", %{conn: conn, data: data} do
      insert(:cms_content_area, cms_page_template_id: data.cms_page_template.id, cms_slot_id: data.cms_slot.id, name: "hero", position: 0, title: "Starter hero")
      {:ok, form_live, _html} = live(conn, ~p"/cms_pages/new")

      assert has_element?(form_live, "#cms_page-form", "starts with a copy of the template's sections")

      {:ok, _edit, html} =
        form_live
        |> form("#cms_page-form", cms_page: %{slug: "from-template", title: "From template", cms_page_template_id: data.cms_page_template.id})
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "1 starter sections"
      assert Enum.map(Cms.get_preview_page_by_slug("from-template").cms_content_areas, & &1.title) == ["Starter hero"]
    end
  end
end
