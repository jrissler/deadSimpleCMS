defmodule DeadSimpleCmsWeb.CmsTestimonialLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase

  import Phoenix.LiveViewTest

  alias DeadSimpleCms.SpecialContent

  setup :base_data

  describe "Index" do
    test "lists testimonials with stars, a quote snippet, who said it and status", %{conn: conn, data: data} do
      hidden = insert(:cms_testimonial, name: "Hidden Fan", stars: 3, visible: false)
      {:ok, index_live, html} = live(conn, ~p"/cms_testimonials")

      assert html =~ "Testimonials"
      refute html =~ "Listing CMS Testimonials"
      assert html =~ data.cms_testimonial.name
      assert html =~ "Founder, Evil Enterprises"
      assert html =~ "James Bond is relentless"
      assert html =~ "…"
      refute html =~ "far more difficult to eliminate than any reasonable person should be"
      assert has_element?(index_live, "#cms_testimonials-#{data.cms_testimonial.id}", "★★★★★")
      assert has_element?(index_live, "#cms_testimonials-#{data.cms_testimonial.id}", "Shown")
      assert has_element?(index_live, "#cms_testimonials-#{hidden.id}", "3 out of 5 stars")
      assert has_element?(index_live, "#cms_testimonials-#{hidden.id}", "Hidden")
    end

    test "shows an empty state when there are no testimonials", %{conn: conn, data: data} do
      {:ok, _} = SpecialContent.delete_cms_testimonial(data.cms_testimonial)
      {:ok, _index_live, html} = live(conn, ~p"/cms_testimonials")

      assert html =~ "No testimonials yet"
    end

    test "saves new testimonial", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_testimonials")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New testimonial")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_testimonials/new")

      html = render(form_live)
      assert html =~ "New testimonial"
      assert html =~ "Their role"
      assert html =~ "Where it was posted"
      assert has_element?(form_live, "select[name='cms_testimonial[stars]'] option[value='5'][selected]", "★★★★★")
      assert has_element?(form_live, "select[name='cms_testimonial[stars]'] option[value='1']", "1 star")

      assert form_live
             |> form("#cms_testimonial-form", cms_testimonial: %{name: "", quote: "", stars: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_testimonial-form", cms_testimonial: params_for(:cms_testimonial, name: "some new name", quote: "some new quote", stars: 4, visible: true))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_testimonials")

      html = render(index_live)
      assert html =~ "Testimonial created"
      assert html =~ "some new name"
      assert [%{stars: 4}] = Enum.filter(SpecialContent.list_cms_testimonials(), &(&1.name == "some new name"))
    end

    test "updates testimonial in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_testimonials")

      assert {:ok, form_live, _} =
               index_live
               |> element("#cms_testimonials-#{data.cms_testimonial.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_testimonials/#{data.cms_testimonial}/edit")

      assert render(form_live) =~ "Edit testimonial"

      assert form_live
             |> form("#cms_testimonial-form", cms_testimonial: %{name: "", quote: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_testimonial-form", cms_testimonial: params_for(:cms_testimonial, name: "some updated name", quote: "some updated quote", stars: 4, visible: false))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_testimonials")

      html = render(index_live)
      assert html =~ "Testimonial saved"
      assert html =~ "some updated name"
      assert has_element?(index_live, "#cms_testimonials-#{data.cms_testimonial.id}", "Hidden")
    end

    test "deletes testimonial in listing with a named confirmation", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_testimonials")

      assert has_element?(index_live, "#cms_testimonials-#{data.cms_testimonial.id} a[data-confirm*='#{data.cms_testimonial.name}']", "Delete")
      assert index_live |> element("#cms_testimonials-#{data.cms_testimonial.id} a", "Delete") |> render_click() =~ "Testimonial from &quot;#{data.cms_testimonial.name}&quot; deleted"
      refute has_element?(index_live, "#cms_testimonials-#{data.cms_testimonial.id}")
    end

    test "deletes the testimonial from the edit form", %{conn: conn, data: data} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_testimonials/#{data.cms_testimonial}/edit")

      {:ok, _index_live, html} = form_live |> element("#delete-cms-testimonial") |> render_click() |> follow_redirect(conn, ~p"/cms_testimonials")
      assert html =~ "Testimonial from &quot;#{data.cms_testimonial.name}&quot; deleted"
    end
  end

  describe "Show" do
    test "displays the testimonial as a quote card", %{conn: conn, data: data} do
      {:ok, show_live, html} = live(conn, ~p"/cms_testimonials/#{data.cms_testimonial}")

      assert html =~ "Testimonial from #{data.cms_testimonial.name}"
      assert has_element?(show_live, "#testimonial-card blockquote", "far more difficult to eliminate")
      assert has_element?(show_live, "#testimonial-card", "★★★★★")
      assert has_element?(show_live, "#testimonial-card figcaption", "Founder, Evil Enterprises · via Google")
      assert html =~ "Shown"
    end

    test "updates testimonial and returns to show", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_testimonials/#{data.cms_testimonial}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit testimonial")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_testimonials/#{data.cms_testimonial}/edit?return_to=show")

      assert render(form_live) =~ "Edit testimonial"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#cms_testimonial-form", cms_testimonial: params_for(:cms_testimonial, name: "some updated name", quote: "some updated quote", stars: 4, visible: false))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_testimonials/#{data.cms_testimonial}")

      html = render(show_live)
      assert html =~ "Testimonial saved"
      assert html =~ "some updated name"
      assert html =~ "Hidden"
    end
  end
end
