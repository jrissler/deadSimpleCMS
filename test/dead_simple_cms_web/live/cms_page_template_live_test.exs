defmodule DeadSimpleCmsWeb.CmsPageTemplateLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase

  import Phoenix.LiveViewTest

  alias DeadSimpleCms.Cms

  setup :base_data

  describe "Index" do
    test "lists templates with how many pages use them", %{conn: conn, data: data} do
      {:ok, index_live, html} = live(conn, ~p"/cms_page_templates")

      assert html =~ "Templates"
      assert has_element?(index_live, "#cms_page_templates-#{data.cms_page_template.id}", data.cms_page_template.name)
      assert has_element?(index_live, "#cms_page_templates-#{data.cms_page_template.id}", "1 page")
    end

    test "creates a template and opens its editor", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_page_templates")

      assert {:ok, form_live, _} = index_live |> element("a", "New template") |> render_click() |> follow_redirect(conn, ~p"/cms_page_templates/new")
      assert render(form_live) =~ "New template"
      assert form_live |> form("#cms_page_template-form", cms_page_template: %{key: "", name: ""}) |> render_change() =~ "can&#39;t be blank"

      assert {:ok, edit_live, html} =
               form_live
               |> form("#cms_page_template-form", cms_page_template: %{key: "landing_page", name: "Landing Page", description: "For landing pages"})
               |> render_submit()
               |> follow_redirect(conn)

      assert html =~ "Template created"
      assert has_element?(edit_live, "#content-areas-empty", "No sections yet")
    end

    test "deletes a template, explaining what happens to its pages", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_page_templates")

      assert has_element?(index_live, "#cms_page_templates-#{data.cms_page_template.id} a[data-confirm*='keep their own sections']", "Delete")
      assert index_live |> element("#cms_page_templates-#{data.cms_page_template.id} a", "Delete") |> render_click() =~ "deleted"
      refute has_element?(index_live, "#cms_page_templates-#{data.cms_page_template.id}")
    end
  end

  describe "Edit" do
    test "saving settings stays on the template and lists the pages using it", %{conn: conn, data: data} do
      {:ok, form_live, html} = live(conn, ~p"/cms_page_templates/#{data.cms_page_template.id}/edit")

      assert html =~ "Used by 1 page (#{data.cms_page.title})"
      assert form_live |> form("#cms_page_template-form", cms_page_template: %{name: "Renamed"}) |> render_submit() =~ "Template settings saved"
      assert Cms.get_cms_page_template!(data.cms_page_template.id).name == "Renamed"
    end

    test "adds, edits and shares template sections with the shared section editor", %{conn: conn, data: data} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_page_templates/#{data.cms_page_template.id}/edit")

      form_live |> element("#content-areas-add") |> render_click()
      assert render(form_live) =~ "Section added"

      [area] = Cms.list_owner_content_areas({:template, data.cms_page_template.id})
      assert area.cms_page_id == nil
      assert area.position == 0

      form_live
      |> form("#content-area-form-#{area.id}", cms_content_area: %{title: "Follow along", body_md: "New episodes every Sunday", shared: true})
      |> render_submit()

      assert render(form_live) =~ "Section saved"
      area = Cms.get_cms_content_area!(area.id)
      assert area.title == "Follow along"
      assert area.shared
      assert has_element?(form_live, "#content-area-#{area.id}-summary", "Shared on every page")
    end
  end

  describe "Show" do
    test "lists the template's sections and the pages using it", %{conn: conn, data: data} do
      insert(:cms_content_area, cms_page_template_id: data.cms_page_template.id, cms_slot_id: data.cms_slot.id, name: "cta", title: "Follow along", shared: true)
      {:ok, show_live, _html} = live(conn, ~p"/cms_page_templates/#{data.cms_page_template}")

      assert has_element?(show_live, "#template-sections", "Follow along")
      assert has_element?(show_live, "#template-sections", "Shared on every page")
      assert has_element?(show_live, "a", data.cms_page.title)
    end
  end
end
