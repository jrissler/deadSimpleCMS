defmodule DeadSimpleCmsWeb.CmsSlotLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase

  import Phoenix.LiveViewTest

  alias DeadSimpleCms.Cms

  setup :base_data

  describe "Index" do
    test "lists section types with how many sections use them", %{conn: conn, data: data} do
      {:ok, index_live, html} = live(conn, ~p"/cms_slots")

      assert html =~ "Section types"
      row = "#cms_slots-#{data.cms_slot.id}"
      assert has_element?(index_live, row, data.cms_slot.name)
      assert has_element?(index_live, "#{row} code", data.cms_slot.key)
      assert has_element?(index_live, row, "1 section")
    end

    test "creates a section type", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_slots")

      assert {:ok, form_live, _} = index_live |> element("a", "New section type") |> render_click() |> follow_redirect(conn, ~p"/cms_slots/new")

      html = render(form_live)
      assert html =~ "New section type"
      assert html =~ "the website&#39;s code matches on"
      assert html =~ "Section type list"

      assert form_live |> form("#cms_slot-form", cms_slot: %{key: "", name: ""}) |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_slot-form", cms_slot: %{key: "hero_intro", name: "Hero Intro", description: "Primary hero area"})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_slots")

      html = render(index_live)
      assert html =~ "Section type &quot;Hero Intro&quot; created"
      assert html =~ "hero_intro"
    end

    test "updates a section type from the listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_slots")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#cms_slots-#{data.cms_slot.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_slots/#{data.cms_slot}/edit")

      html = render(form_live)
      assert html =~ "Edit section type"
      assert html =~ "breaks the 1 section using this type"

      assert form_live |> form("#cms_slot-form", cms_slot: %{key: "", name: ""}) |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_slot-form", cms_slot: %{key: "primary_cta", name: "Primary CTA", description: "Updated slot description"})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_slots")

      html = render(index_live)
      assert html =~ "Section type saved"
      assert html =~ "primary_cta"
    end

    test "won't delete a section type that's in use", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_slots")

      html = index_live |> element("#cms_slots-#{data.cms_slot.id} a", "Delete") |> render_click()
      assert html =~ "&quot;#{data.cms_slot.name}&quot; is used by 1 section. Change their type first."
      assert has_element?(index_live, "#cms_slots-#{data.cms_slot.id}")
      assert Cms.get_cms_slot!(data.cms_slot.id)
    end

    test "deletes an unused section type after naming it", %{conn: conn} do
      unused = insert(:cms_slot, name: "Old banner")
      {:ok, index_live, _html} = live(conn, ~p"/cms_slots")

      assert has_element?(index_live, "#cms_slots-#{unused.id} a[data-confirm*='Old banner']", "Delete")
      assert index_live |> element("#cms_slots-#{unused.id} a", "Delete") |> render_click() =~ "Section type &quot;Old banner&quot; deleted"
      refute has_element?(index_live, "#cms_slots-#{unused.id}")
    end
  end

  describe "Show" do
    test "lists the sections using the type, linked to their page or template", %{conn: conn, data: data} do
      template_area = insert(:cms_content_area, cms_page_template_id: data.cms_page_template.id, cms_slot_id: data.cms_slot.id)
      {:ok, show_live, html} = live(conn, ~p"/cms_slots/#{data.cms_slot}")

      assert html =~ data.cms_slot.name
      assert html =~ data.cms_slot.key
      assert html =~ "Used by 2 sections"
      assert has_element?(show_live, "#slot-section-#{data.cms_content_area.id} a[href='/cms_pages/#{data.cms_page.id}/edit']", "Open page")
      assert has_element?(show_live, "#slot-section-#{template_area.id}", "Template: #{data.cms_page_template.name}")
      assert has_element?(show_live, "#slot-section-#{template_area.id} a[href='/cms_page_templates/#{data.cms_page_template.id}/edit']", "Open template")
    end

    test "edits the section type and returns to it", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_slots/#{data.cms_slot}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit section type")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_slots/#{data.cms_slot}/edit?return_to=show")

      assert {:ok, show_live, _html} =
               form_live
               |> form("#cms_slot-form", cms_slot: %{key: "primary_cta", name: "Primary CTA", description: "Updated slot description"})
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_slots/#{data.cms_slot}")

      html = render(show_live)
      assert html =~ "Section type saved"
      assert html =~ "primary_cta"
    end
  end

  describe "Edit" do
    test "blocks deleting a type in use from the form", %{conn: conn, data: data} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_slots/#{data.cms_slot}/edit")

      assert form_live |> element("#delete-cms-slot") |> render_click() =~ "is used by 1 section"
      assert Cms.get_cms_slot!(data.cms_slot.id)
    end
  end
end
