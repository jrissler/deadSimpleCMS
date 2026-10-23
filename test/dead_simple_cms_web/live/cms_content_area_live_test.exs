defmodule DeadSimpleCmsWeb.CmsContentAreaLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase
  import Phoenix.LiveViewTest

  alias DeadSimpleCms.Cms

  setup :base_data

  defp area_params(data, attrs \\ %{}) do
    Map.merge(%{owner: "page:#{data.cms_page.id}", cms_slot_id: data.cms_slot.id, name: "some name", title: "some title", subtitle: "some subtitle", body_md: "some body", visible: true}, attrs)
  end

  describe "Index" do
    test "lists sections with their page, type and status", %{conn: conn, data: data} do
      template_area = insert(:cms_content_area, cms_page_template_id: data.cms_page_template.id, cms_slot_id: data.cms_slot.id, shared: true, visible: false)
      {:ok, index_live, html} = live(conn, ~p"/cms_content_areas")

      assert html =~ "Sections"
      assert html =~ "usually edited from their page or template"
      row = "#cms_content_areas-#{data.cms_content_area.id}"
      assert has_element?(index_live, row, data.cms_content_area.title)
      assert has_element?(index_live, row, data.cms_page.title)
      assert has_element?(index_live, row, data.cms_slot.name)
      assert has_element?(index_live, row, "Shown")
      refute has_element?(index_live, "#{row} td", data.cms_page.id)
      assert has_element?(index_live, "#{row} a[href='/cms_pages/#{data.cms_page.id}/edit']", "Open page")

      template_row = "#cms_content_areas-#{template_area.id}"
      assert has_element?(index_live, template_row, "Template: #{data.cms_page_template.name}")
      assert has_element?(index_live, template_row, "Hidden")
      assert has_element?(index_live, template_row, "Shared")
      assert has_element?(index_live, "#{template_row} a[href='/cms_page_templates/#{data.cms_page_template.id}/edit']", "Open template")
    end

    test "creates a section", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_content_areas")

      assert {:ok, form_live, _} = index_live |> element("a", "New section") |> render_click() |> follow_redirect(conn, ~p"/cms_content_areas/new")
      assert render(form_live) =~ "New section"
      assert render(form_live) =~ "Section type"
      refute render(form_live) =~ "NOTE"

      assert form_live |> form("#cms_content_area-form", cms_content_area: area_params(data, %{name: ""})) |> render_change() =~ "can&#39;t be blank"
      assert form_live |> form("#cms_content_area-form", cms_content_area: area_params(data, %{owner: ""})) |> render_change() =~ "choose a page or template"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_content_area-form", cms_content_area: area_params(data, %{name: "some new name", title: "Brand new section"}))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_content_areas")

      html = render(index_live)
      assert html =~ "Section created"
      assert html =~ "Brand new section"

      area = Enum.find(Cms.list_cms_content_areas(), &(&1.name == "some new name"))
      assert area.cms_page_id == data.cms_page.id
      # Order defaults to the end of the page.
      assert area.position > data.cms_content_area.position
    end

    test "shows Shared only for template sections and saves it", %{conn: conn, data: data} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_content_areas/new")

      refute has_element?(form_live, "input[type=checkbox][name='cms_content_area[shared]']")
      form_live |> form("#cms_content_area-form", cms_content_area: area_params(data, %{owner: "template:#{data.cms_page_template.id}"})) |> render_change()
      assert has_element?(form_live, "input[type=checkbox][name='cms_content_area[shared]']")

      assert {:ok, _index_live, _html} =
               form_live
               |> form("#cms_content_area-form", cms_content_area: area_params(data, %{owner: "template:#{data.cms_page_template.id}", name: "shared-cta", shared: true}))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_content_areas")

      area = Enum.find(Cms.list_cms_content_areas(), &(&1.name == "shared-cta"))
      assert area.cms_page_template_id == data.cms_page_template.id
      assert is_nil(area.cms_page_id)
      assert area.shared
    end

    test "updates a section from the listing", %{conn: conn, data: data} do
      # Rows open the editor when clicked; there's no separate Edit link.
      {:ok, form_live, _} = live(conn, ~p"/cms_content_areas/#{data.cms_content_area}/edit")

      html = render(form_live)
      assert html =~ "Edit section"
      assert html =~ "Image description"
      refute html =~ "Content-Type"

      assert form_live |> form("#cms_content_area-form", cms_content_area: area_params(data, %{name: ""})) |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_content_area-form", cms_content_area: area_params(data, %{name: "some updated name", position: 43, visible: false}), image_alt: "A boat at sunset")
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_content_areas")

      html = render(index_live)
      assert html =~ "Section saved"
      assert html =~ "some title"
      assert Cms.get_cms_image!(data.cms_image.id).alt == "A boat at sunset"
    end

    test "removes the image from a section on save", %{conn: conn, data: data} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_content_areas/#{data.cms_content_area}/edit")

      form_live |> element("#remove-image") |> render_click()
      assert has_element?(form_live, "#image-removed")

      assert {:ok, _live, _html} = form_live |> form("#cms_content_area-form", cms_content_area: area_params(data)) |> render_submit() |> follow_redirect(conn, ~p"/cms_content_areas")
      assert is_nil(Cms.get_cms_content_area!(data.cms_content_area.id).cms_image_id)
      assert Cms.get_cms_image!(data.cms_image.id)
    end

    test "deletes a section, naming it", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_content_areas")

      assert has_element?(index_live, "#cms_content_areas-#{data.cms_content_area.id} a[data-confirm*='#{data.cms_content_area.title}']", "Delete")
      assert index_live |> element("#cms_content_areas-#{data.cms_content_area.id} a", "Delete") |> render_click() =~ "Section &quot;#{data.cms_content_area.title}&quot; deleted"
      refute has_element?(index_live, "#cms_content_areas-#{data.cms_content_area.id}")
    end
  end

  describe "Show" do
    test "summarizes the section", %{conn: conn, data: data} do
      {:ok, show_live, html} = live(conn, ~p"/cms_content_areas/#{data.cms_content_area}")

      assert html =~ data.cms_content_area.title
      assert html =~ data.cms_slot.name
      assert html =~ "Shown"
      assert html =~ data.cms_image.alt
      refute has_element?(show_live, "dd", data.cms_page.id)
      assert has_element?(show_live, "a[href='/cms_pages/#{data.cms_page.id}/edit']", data.cms_page.title)
      assert has_element?(show_live, "#section-image img[src='#{data.cms_image.url}']")
      assert has_element?(show_live, "#section-body", "Some **markdown** content.")
    end

    test "edits the section and returns to it", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_content_areas/#{data.cms_content_area}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit section")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_content_areas/#{data.cms_content_area}/edit?return_to=show")

      assert {:ok, show_live, _html} =
               form_live
               |> form("#cms_content_area-form", cms_content_area: area_params(data, %{title: "some updated title"}))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_content_areas/#{data.cms_content_area}")

      html = render(show_live)
      assert html =~ "Section saved"
      assert html =~ "some updated title"
    end
  end
end
