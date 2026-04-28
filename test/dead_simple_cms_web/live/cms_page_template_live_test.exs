defmodule DeadSimpleCmsWeb.CmsPageTemplateLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase

  import Phoenix.LiveViewTest

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Repo

  setup :base_data

  describe "Index" do
    test "lists all cms_page_templates", %{conn: conn, data: data} do
      {:ok, _index_live, html} = live(conn, ~p"/cms_page_templates")

      assert html =~ "Listing CMS Page Templates"
      assert html =~ data.cms_page_template.key
    end

    test "saves new cms_page_template and redirects to edit", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_page_templates")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Add CMS Page Template")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_page_templates/new")

      assert render(form_live) =~ "New CMS Page Template"

      assert form_live
             |> form("#cms_page_template-form", cms_page_template: %{key: "", name: "", description: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, _edit_live, html} =
               form_live
               |> form("#cms_page_template-form", cms_page_template: %{key: "landing_page", name: "Landing Page", description: "Template for landing_page"})
               |> render_submit()
               |> follow_redirect(conn)

      assert html =~ "Cms page template created successfully"
      assert html =~ "Edit CMS Page Template"
      assert html =~ "landing_page"
      assert html =~ "Content Areas"
    end

    test "updates cms_page_template in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_page_templates")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#cms_page_templates-#{data.cms_page_template.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_page_templates/#{data.cms_page_template.id}/edit")

      assert render(form_live) =~ "Edit CMS Page Template"

      assert form_live
             |> form("#cms_page_template-form", cms_page_template: %{key: "", name: "", description: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_page_template-form", cms_page_template: %{key: "landing_page", name: "Landing Page", description: "Updated description"})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_page_templates")

      html = render(index_live)
      assert html =~ "Cms page template updated successfully"
      assert html =~ "landing_page"
    end

    test "adds and updates content area while editing cms_page_template", %{conn: conn, data: data} do
      {:ok, form_live, html} = live(conn, ~p"/cms_page_templates/#{data.cms_page_template.id}/edit")

      assert html =~ "Edit CMS Page Template"
      assert html =~ "Content Areas"

      form_live |> element("button", "Add Content Area") |> render_click()

      html = render(form_live)
      assert html =~ "Content area added"
      assert html =~ "New Content Area"

      cms_page_template = data.cms_page_template |> Repo.reload!() |> Repo.preload(:cms_content_areas)
      assert length(cms_page_template.cms_content_areas) == 1

      default_slot = Cms.list_cms_slots() |> List.first()

      [content_area] = cms_page_template.cms_content_areas
      assert content_area.cms_page_template_id == data.cms_page_template.id
      assert content_area.cms_page_id == nil
      assert content_area.cms_slot_id == default_slot.id
      assert content_area.position == 1

      assert form_live
             |> form("#content-area-form-#{content_area.id}", _id: content_area.id, cms_content_area: %{cms_slot_id: default_slot.id, name: "Years in Business", visible: true, title: "35+", subtitle: "Years in Business", body_md: "Since 1989"})
             |> render_submit() =~ "Content area saved"

      content_area = Cms.get_cms_content_area!(content_area.id)

      assert content_area.name == "Years in Business"
      assert content_area.title == "35+"
      assert content_area.subtitle == "Years in Business"
      assert content_area.body_md == "Since 1989"
      assert content_area.cms_page_template_id == data.cms_page_template.id
    end

    test "deletes cms_page_template in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_page_templates")

      assert index_live |> element("#cms_page_templates-#{data.cms_page_template.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#cms_page_templates-#{data.cms_page_template.id}")
    end
  end

  describe "Show" do
    test "displays cms_page_template", %{conn: conn, data: data} do
      {:ok, _show_live, html} = live(conn, ~p"/cms_page_templates/#{data.cms_page_template}")

      assert html =~ "Viewing CMS Page Template"
      assert html =~ data.cms_page_template.name
    end

    test "updates cms_page_template and returns to show", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_page_templates/#{data.cms_page_template}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit Template")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_page_templates/#{data.cms_page_template.id}/edit?return_to=show")

      assert render(form_live) =~ "Edit CMS Page Template"

      assert form_live
             |> form("#cms_page_template-form", cms_page_template: %{key: "", name: "", description: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#cms_page_template-form", cms_page_template: %{key: "landing_page", name: "Landing Page", description: "Updated description"})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_page_templates/#{data.cms_page_template.id}")

      html = render(show_live)
      assert html =~ "Cms page template updated successfully"
      assert html =~ "landing_page"
    end
  end
end
