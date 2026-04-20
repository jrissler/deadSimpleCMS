defmodule DeadSimpleCmsWeb.CmsPageTemplateLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :base_data

  describe "Index" do
    test "lists all cms_page_templates", %{conn: conn, data: data} do
      {:ok, _index_live, html} = live(conn, ~p"/cms_page_templates")

      assert html =~ "Listing CMS Page Templates"
      assert html =~ data.cms_page_template.key
    end

    test "saves new cms_page_template", %{conn: conn} do
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

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_page_template-form", cms_page_template: %{key: "landing_page", name: "Landing Page", description: "Template for landing_page"})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_page_templates")

      html = render(index_live)
      assert html =~ "Cms page template created successfully"
      assert html =~ "landing_page"
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
