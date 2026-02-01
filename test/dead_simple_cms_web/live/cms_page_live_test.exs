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

    test "saves new cms_page", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_pages")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Add CMS Page")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_pages/new")

      assert render(form_live) =~ "New Cms page"

      assert form_live
             |> form("#cms_page-form", cms_page: params_for(:cms_page, slug: "some slug", title: ""))
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_page-form", cms_page: params_for(:cms_page, slug: "some slug", title: "some new title"))
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

      assert render(form_live) =~ "Edit Cms page"

      assert form_live
             |> form("#cms_page-form", cms_page: params_for(:cms_page, title: ""))
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_page-form", cms_page: params_for(:cms_page, title: "some updated title"))
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

    test "updates cms_page and returns to show", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_pages/#{data.cms_page}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_pages/#{data.cms_page}/edit?return_to=show")

      assert render(form_live) =~ "Edit Cms page"

      assert form_live
             |> form("#cms_page-form", cms_page: params_for(:cms_page, title: ""))
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#cms_page-form", cms_page: params_for(:cms_page, title: "some updated title"))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_pages/#{data.cms_page}")

      html = render(show_live)
      assert html =~ "Cms page updated successfully"
      assert html =~ "some updated title"
    end
  end
end
