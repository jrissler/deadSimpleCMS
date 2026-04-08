defmodule DeadSimpleCmsWeb.CmsSlotLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :base_data

  describe "Index" do
    test "lists all cms_slots", %{conn: conn, data: data} do
      {:ok, _index_live, html} = live(conn, ~p"/cms_slots")

      assert html =~ "Listing CMS Slots"
      assert html =~ data.cms_slot.key
    end

    test "saves new cms_slot", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_slots")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Add CMS Slot")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_slots/new")

      assert render(form_live) =~ "New Cms slot"

      assert form_live
             |> form("#cms_slot-form", cms_slot: params_for(:cms_slot, key: "", name: ""))
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_slot-form", cms_slot: params_for(:cms_slot, key: "hero_intro", name: "Hero Intro", description: "Primary hero area"))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_slots")

      html = render(index_live)
      assert html =~ "Cms slot created successfully"
      assert html =~ "hero_intro"
    end

    test "updates cms_slot in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_slots")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#cms_slots-#{data.cms_slot.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_slots/#{data.cms_slot}/edit")

      assert render(form_live) =~ "Edit Cms slot"

      assert form_live
             |> form("#cms_slot-form", cms_slot: %{key: "", name: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_slot-form", cms_slot: params_for(:cms_slot, key: "primary_cta", name: "Primary CTA", description: "Updated slot description"))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_slots")

      html = render(index_live)
      assert html =~ "Cms slot updated successfully"
      assert html =~ "primary_cta"
    end

    test "deletes cms_slot in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_slots")

      assert index_live |> element("#cms_slots-#{data.cms_slot.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#cms_slots-#{data.cms_slot.id}")
    end
  end

  describe "Show" do
    test "displays cms_slot", %{conn: conn, data: data} do
      {:ok, _show_live, html} = live(conn, ~p"/cms_slots/#{data.cms_slot}")

      assert html =~ "Viewing CMS Slot"
      assert html =~ data.cms_slot.key
    end

    test "updates cms_slot and returns to show", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_slots/#{data.cms_slot}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_slots/#{data.cms_slot}/edit?return_to=show")

      assert render(form_live) =~ "Edit Cms slot"

      assert form_live
             |> form("#cms_slot-form", cms_slot: %{key: "", name: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#cms_slot-form", cms_slot: params_for(:cms_slot, key: "primary_cta", name: "Primary CTA", description: "Updated slot description"))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_slots/#{data.cms_slot}")

      html = render(show_live)
      assert html =~ "Cms slot updated successfully"
      assert html =~ "primary_cta"
    end
  end
end
