defmodule DeadSimpleCmsWeb.CmsBioLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :base_data

  describe "Index" do
    test "lists all cms_bios", %{conn: conn, data: data} do
      {:ok, _index_live, html} = live(conn, ~p"/cms_bios")

      assert html =~ "Listing CMS Bios"
      assert html =~ data.cms_bio.name
    end

    test "saves new cms_bio", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_bios")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Add CMS Bio")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_bios/new")

      assert render(form_live) =~ "New Cms bio"

      assert form_live
             |> form("#cms_bio-form", cms_bio: params_for(:cms_bio, name: nil))
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_bio-form", cms_bio: params_for(:cms_bio, name: "some new name", slug: "some-new-name"))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_bios")

      html = render(index_live)
      assert html =~ "Cms bio created successfully"
      assert html =~ "some-new-name"
      assert html =~ "some new name"
    end

    test "updates cms_bio in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_bios")

      assert {:ok, form_live, _} =
               index_live
               |> element("#cms_bios-#{data.cms_bio.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_bios/#{data.cms_bio}/edit")

      assert render(form_live) =~ "Edit Cms bio"

      assert form_live
             |> form("#cms_bio-form", cms_bio: %{name: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_bio-form", cms_bio: params_for(:cms_bio, name: "some updated name", slug: "some-updated-slug", visible: false, cms_image_id: data.cms_image.id))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_bios")

      html = render(index_live)
      assert html =~ "Cms bio updated successfully"
      assert html =~ "some-updated-slug"
      assert html =~ "some updated name"
    end

    test "deletes cms_bio in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_bios")

      assert index_live |> element("#cms_bios-#{data.cms_bio.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#cms_bios-#{data.cms_bio.id}")
    end
  end

  describe "Show" do
    test "displays cms_bio", %{conn: conn, data: data} do
      {:ok, _show_live, html} = live(conn, ~p"/cms_bios/#{data.cms_bio}")

      assert html =~ "Viewing CMS Bio"
      assert html =~ data.cms_bio.name
    end

    test "updates cms_bio and returns to show", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_bios/#{data.cms_bio}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit Bio")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_bios/#{data.cms_bio}/edit?return_to=show")

      assert render(form_live) =~ "Edit Cms bio"

      assert form_live
             |> form("#cms_bio-form", cms_bio: %{name: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#cms_bio-form", cms_bio: params_for(:cms_bio, name: "some updated name", slug: "some-updated-slug", cms_image_id: data.cms_image.id))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_bios/#{data.cms_bio}")

      html = render(show_live)
      assert html =~ "Cms bio updated successfully"
      assert html =~ "some updated name"
      assert html =~ "some-updated-slug"
    end
  end
end
