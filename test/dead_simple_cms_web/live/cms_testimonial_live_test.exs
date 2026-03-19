defmodule DeadSimpleCmsWeb.CmsTestimonialLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :base_data

  describe "Index" do
    test "lists all cms_testimonials", %{conn: conn, data: data} do
      {:ok, _index_live, html} = live(conn, ~p"/cms_testimonials")

      assert html =~ "Listing CMS Testimonials"
      assert html =~ data.cms_testimonial.name
    end

    test "saves new cms_testimonial", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_testimonials")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Add CMS Testimonial")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_testimonials/new")

      assert render(form_live) =~ "New Cms testimonial"

      assert form_live
             |> form("#cms_testimonial-form", cms_testimonial: %{name: nil, quote: nil, stars: nil})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_testimonial-form", cms_testimonial: params_for(:cms_testimonial, name: "some new name", quote: "some new quote", stars: 5, visible: true))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_testimonials")

      html = render(index_live)
      assert html =~ "Cms testimonial created successfully"
      assert html =~ "some new name"
    end

    test "updates cms_testimonial in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_testimonials")

      assert {:ok, form_live, _} =
               index_live
               |> element("#cms_testimonials-#{data.cms_testimonial.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_testimonials/#{data.cms_testimonial}/edit")

      assert render(form_live) =~ "Edit Cms testimonial"

      assert form_live
             |> form("#cms_testimonial-form", cms_testimonial: %{name: "", quote: "", stars: nil})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_testimonial-form", cms_testimonial: params_for(:cms_testimonial, name: "some updated name", quote: "some updated quote", stars: 4, visible: false))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_testimonials")

      html = render(index_live)
      assert html =~ "Cms testimonial updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes cms_testimonial in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_testimonials")

      assert index_live |> element("#cms_testimonials-#{data.cms_testimonial.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#cms_testimonials-#{data.cms_testimonial.id}")
    end
  end

  describe "Show" do
    test "displays cms_testimonial", %{conn: conn, data: data} do
      {:ok, _show_live, html} = live(conn, ~p"/cms_testimonials/#{data.cms_testimonial}")

      assert html =~ "Viewing CMS Testimonial"
      assert html =~ data.cms_testimonial.name
    end

    test "updates cms_testimonial and returns to show", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_testimonials/#{data.cms_testimonial}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit Testimonial")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_testimonials/#{data.cms_testimonial}/edit?return_to=show")

      assert render(form_live) =~ "Edit Cms testimonial"

      assert form_live
             |> form("#cms_testimonial-form", cms_testimonial: %{name: "", quote: "", stars: nil})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#cms_testimonial-form", cms_testimonial: params_for(:cms_testimonial, name: "some updated name", quote: "some updated quote", stars: 4, visible: false))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_testimonials/#{data.cms_testimonial}")

      html = render(show_live)
      assert html =~ "Cms testimonial updated successfully"
      assert html =~ "some updated name"
    end
  end
end
