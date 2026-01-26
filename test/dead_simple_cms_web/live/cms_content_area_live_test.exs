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
      {:ok, index_live, _html} = live(conn, DeadSimpleCms.path("/cms_content_areas"))

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Cms content area")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_content_areas/new")

      assert render(form_live) =~ "New Cms content area"

      assert form_live |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: nil, cms_page_id: data.cms_page.id, cms_image_id: data.cms_image.id)) |> render_change() =~ "can&#39;t be blank"
      assert form_live |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: nil, cms_page_id: data.cms_page.id, icms_mage_id: data.cms_image.id)) |> render_submit() =~ "can&#39;t be blank"

      assert form_live |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: "some name", page_id: data.cms_page.id, image_id: data.cms_image.id)) |> render_submit()

      # assert_patch(index_live, DeadSimpleCms.path("/cms_content_areas"))

      # html = render(index_live)
      # assert html =~ "Cms content area created successfully"
      # assert html =~ "some name"
    end

    #   test "updates cms_content_area in listing", %{conn: conn, data: data} do
    #     {:ok, index_live, _html} = live(conn, DeadSimpleCms.path("/cms_content_areas"))

    #     assert index_live |> element("#cms_content_areas-#{data.cms_content_area.id} a", "Edit") |> render_click() =~ "Edit Cms content area"
    #     assert_patch(index_live, DeadSimpleCms.path("/cms_content_areas/#{data.cms_content_area.id}/edit"))

    #     assert index_live |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: nil, position: nil, title: nil, subtitle: nil, body_md: nil, page_id: data.cms_page.id, image_id: data.cms_image.id) |> Map.drop(@non_form_fields)) |> render_change() =~ "can&#39;t be blank"
    #     assert index_live |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: nil, position: nil, title: nil, subtitle: nil, body_md: nil, page_id: data.cms_page.id, image_id: data.cms_image.id) |> Map.drop(@non_form_fields)) |> render_submit() =~ "can&#39;t be blank"

    #     assert index_live |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: "some updated name", position: 43, visible: false, title: "some updated title", subtitle: "some updated subtitle", body_md: "some updated body_md", page_id: data.cms_page.id, image_id: data.cms_image.id) |> Map.drop(@non_form_fields)) |> render_submit()

    #     assert_patch(index_live, DeadSimpleCms.path("/cms_content_areas"))

    #     html = render(index_live)
    #     assert html =~ "Cms content area updated successfully"
    #     assert html =~ "some updated name"
    #   end

    #   test "deletes cms_content_area in listing", %{conn: conn, data: data} do
    #     {:ok, index_live, _html} = live(conn, DeadSimpleCms.path("/cms_content_areas"))

    #     assert index_live |> element("#cms_content_areas-#{data.cms_content_area.id} a", "Delete") |> render_click()
    #     refute has_element?(index_live, "#cms_content_areas-#{data.cms_content_area.id}")
    #   end
  end

  # describe "Show" do
  #   test "displays cms_content_area", %{conn: conn, data: data} do
  #     {:ok, _show_live, html} = live(conn, DeadSimpleCms.path("/cms_content_areas/#{data.cms_content_area.id}"))
  #     assert html =~ "Show Cms content area"
  #     assert html =~ data.cms_content_area.name
  #   end

  #   test "updates cms_content_area and returns to show", %{conn: conn, data: data} do
  #     {:ok, show_live, _html} = live(conn, DeadSimpleCms.path("/cms_content_areas/#{data.cms_content_area.id}"))

  #     assert show_live |> element("a", "Edit") |> render_click() =~ "Edit Cms content area"
  #     assert_patch(show_live, DeadSimpleCms.path("/cms_content_areas/#{data.cms_content_area.id}/edit?return_to=show"))

  #     assert show_live |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: nil, position: nil, title: nil, subtitle: nil, body_md: nil, page_id: data.cms_page.id, image_id: data.cms_image.id) |> Map.drop(@non_form_fields)) |> render_change() =~ "can&#39;t be blank"
  #     assert show_live |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: nil, position: nil, title: nil, subtitle: nil, body_md: nil, page_id: data.cms_page.id, image_id: data.cms_image.id) |> Map.drop(@non_form_fields)) |> render_submit() =~ "can&#39;t be blank"

  #     assert show_live |> form("#cms_content_area-form", cms_content_area: params_for(:cms_content_area, name: "some updated name", position: 43, visible: false, title: "some updated title", subtitle: "some updated subtitle", body_md: "some updated body_md", page_id: data.cms_page.id, image_id: data.cms_image.id) |> Map.drop(@non_form_fields)) |> render_submit()

  #     assert_patch(show_live, DeadSimpleCms.path("/cms_content_areas/#{data.cms_content_area.id}"))

  #     html = render(show_live)
  #     assert html =~ "Cms content area updated successfully"
  #     assert html =~ "some updated name"
  #   end
  # end
end
