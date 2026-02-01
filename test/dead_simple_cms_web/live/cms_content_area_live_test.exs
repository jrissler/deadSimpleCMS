defmodule DeadSimpleCmsWeb.CmsContentAreaLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase
  import Phoenix.LiveViewTest

  setup :base_data

  describe "Index" do
    test "lists all cms_content_areas", %{conn: conn, data: data} do
      {:ok, _index_live, html} = live(conn, ~p"/cms_content_areas")

      assert html =~ "Listing Cms content areas"
      assert html =~ data.cms_content_area.name
    end

    test "saves new cms_content_area", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_content_areas")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Add CMS Content Area")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_content_areas/new")

      assert render(form_live) =~ "New Cms content area"

      assert form_live
             |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: nil, cms_page_id: data.cms_page.id, cms_image_id: data.cms_image.id))
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: "some new name", cms_page_id: data.cms_page.id, cms_image_id: data.cms_image.id))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_content_areas")

      html = render(index_live)
      assert html =~ "Cms content area created successfully"
      assert html =~ "some new name"
    end

    test "updates cms_content_area in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_content_areas")

      assert {:ok, form_live, _} =
               index_live
               |> element("#cms_content_areas-#{data.cms_content_area.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_content_areas/#{data.cms_content_area}/edit")

      assert render(form_live) =~ "Edit Cms content area"

      assert form_live
             |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: "", cms_page_id: data.cms_page.id, cms_image_id: data.cms_image.id))
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: "some updated name", position: 43, visible: false, title: "some updated title", subtitle: "some updated subtitle", body_md: "some updated body_md", cms_page_id: data.cms_page.id, cms_image_id: data.cms_image.id))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_content_areas")

      html = render(index_live)
      assert html =~ "Cms content area updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes cms_content_area in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_content_areas")

      assert index_live |> element("#cms_content_areas-#{data.cms_content_area.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#cms_content_areas-#{data.cms_content_area.id}")
    end
  end

  describe "Show" do
    test "displays cms_content_area", %{conn: conn, data: data} do
      {:ok, _show_live, html} = live(conn, ~p"/cms_content_areas/#{data.cms_content_area}")

      assert html =~ "Viewing CMS Content Area"
      assert html =~ data.cms_content_area.name
    end

    test "updates cms_content_area and returns to show", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_content_areas/#{data.cms_content_area}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_content_areas/#{data.cms_content_area}/edit?return_to=show")

      assert render(form_live) =~ "Edit Cms content area"

      assert form_live
             |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: "", cms_page_id: data.cms_page.id, cms_image_id: data.cms_image.id))
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: "some updated name", position: 43, visible: false, title: "some updated title", subtitle: "some updated subtitle", body_md: "some updated body_md", cms_page_id: data.cms_page.id, cms_image_id: data.cms_image.id))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_content_areas/#{data.cms_content_area}")

      html = render(show_live)
      assert html =~ "Cms content area updated successfully"
      assert html =~ "some updated name"
    end
  end
end
