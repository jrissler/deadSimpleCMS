defmodule DeadSimpleCmsWeb.CmsBioLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase

  import Phoenix.LiveViewTest

  alias DeadSimpleCms.SpecialContent

  setup :base_data

  describe "Index" do
    test "lists bios with photo, job title and status", %{conn: conn, data: data} do
      hidden = insert(:cms_bio, name: "Hidden Person", visible: false)
      {:ok, index_live, html} = live(conn, ~p"/cms_bios")

      assert html =~ "Bios"
      refute html =~ "Listing CMS Bios"
      assert html =~ data.cms_bio.name
      assert html =~ data.cms_bio.job_title
      assert has_element?(index_live, "#cms_bios-#{data.cms_bio.id} img[src='#{data.cms_image.url}']")
      assert has_element?(index_live, "#cms_bios-#{data.cms_bio.id}", "Shown")
      assert has_element?(index_live, "#cms_bios-#{hidden.id}", "Hidden")
      refute html =~ ">true<"
    end

    test "shows an empty state when there are no bios", %{conn: conn, data: data} do
      {:ok, _} = SpecialContent.delete_cms_bio(data.cms_bio)
      {:ok, _index_live, html} = live(conn, ~p"/cms_bios")

      assert html =~ "No bios yet"
    end

    test "saves new bio", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_bios")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New bio")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_bios/new")

      html = render(form_live)
      assert html =~ "New bio"
      assert html =~ "TikTok"
      assert html =~ "LinkedIn"
      assert html =~ "Profile address"
      assert html =~ "https://instagram.com/yourname"
      refute html =~ "1 image per bio"
      assert has_element?(form_live, "input[type='email'][name='cms_bio[email]']")
      assert has_element?(form_live, "input[type='tel'][name='cms_bio[phone_number]']")

      assert form_live
             |> form("#cms_bio-form", cms_bio: params_for(:cms_bio, name: nil))
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_bio-form", cms_bio: params_for(:cms_bio, name: "some new name", slug: "some-new-name"))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_bios")

      html = render(index_live)
      assert html =~ "Bio created"
      assert html =~ "some new name"
    end

    test "fills the profile address from the name when left blank", %{conn: conn} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_bios/new")

      {:ok, _index_live, _html} =
        form_live
        |> form("#cms_bio-form", cms_bio: params_for(:cms_bio, name: "Jane Q. Smith", slug: ""))
        |> render_submit()
        |> follow_redirect(conn, ~p"/cms_bios")

      assert SpecialContent.get_cms_bio_by_slug!("jane-q-smith").name == "Jane Q. Smith"
    end

    test "adds https:// to social links typed without it and checks the email", %{conn: conn} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_bios/new")

      assert form_live
             |> form("#cms_bio-form", cms_bio: params_for(:cms_bio, email: "not-an-email"))
             |> render_change() =~ "doesn&#39;t look like an email address"

      {:ok, _index_live, _html} =
        form_live
        |> form("#cms_bio-form", cms_bio: params_for(:cms_bio, name: "Social Person", slug: "social-person", instagram: "instagram.com/social"))
        |> render_submit()
        |> follow_redirect(conn, ~p"/cms_bios")

      assert SpecialContent.get_cms_bio_by_slug!("social-person").instagram == "https://instagram.com/social"
    end

    test "updates bio in listing", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_bios")

      assert {:ok, form_live, _} =
               index_live
               |> element("#cms_bios-#{data.cms_bio.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_bios/#{data.cms_bio}/edit")

      assert render(form_live) =~ "Edit bio"

      assert form_live
             |> form("#cms_bio-form", cms_bio: %{name: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#cms_bio-form", cms_bio: params_for(:cms_bio, name: "some updated name", slug: "some-updated-slug", visible: false))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_bios")

      html = render(index_live)
      assert html =~ "Bio saved"
      assert html =~ "some updated name"
      assert has_element?(index_live, "#cms_bios-#{data.cms_bio.id}", "Hidden")
    end

    test "deletes bio in listing with a named confirmation", %{conn: conn, data: data} do
      {:ok, index_live, _html} = live(conn, ~p"/cms_bios")

      assert has_element?(index_live, "#cms_bios-#{data.cms_bio.id} a[data-confirm*='#{data.cms_bio.name}']", "Delete")
      assert index_live |> element("#cms_bios-#{data.cms_bio.id} a", "Delete") |> render_click() =~ "Bio &quot;#{data.cms_bio.name}&quot; deleted"
      refute has_element?(index_live, "#cms_bios-#{data.cms_bio.id}")
    end
  end

  describe "Form photo" do
    test "shows the photo near the top with its description and removes it", %{conn: conn, data: data} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_bios/#{data.cms_bio}/edit")

      assert has_element?(form_live, "#bio-photo img[src='#{data.cms_image.url}']")
      assert has_element?(form_live, "#bio-image-alt[value='#{data.cms_image.alt}']")

      html = form_live |> element("#remove-bio-photo") |> render_click()
      assert html =~ "Photo removed from the bio"
      refute has_element?(form_live, "#bio-photo img")
      refute has_element?(form_live, "#remove-bio-photo")
      assert SpecialContent.get_cms_bio!(data.cms_bio.id).cms_image_id == nil
    end

    test "saves a new description for the current photo", %{conn: conn, data: data} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_bios/#{data.cms_bio}/edit")

      {:ok, _index_live, _html} =
        form_live
        |> form("#cms_bio-form", cms_bio: %{name: data.cms_bio.name}, image_alt: "James at the helm")
        |> render_submit()
        |> follow_redirect(conn, ~p"/cms_bios")

      assert DeadSimpleCms.Cms.get_cms_image!(data.cms_image.id).alt == "James at the helm"
    end

    test "deletes the bio from the edit form", %{conn: conn, data: data} do
      {:ok, form_live, _html} = live(conn, ~p"/cms_bios/#{data.cms_bio}/edit")

      assert has_element?(form_live, "#delete-cms-bio[data-confirm*='#{data.cms_bio.name}']")

      {:ok, _index_live, html} = form_live |> element("#delete-cms-bio") |> render_click() |> follow_redirect(conn, ~p"/cms_bios")
      assert html =~ "Bio &quot;#{data.cms_bio.name}&quot; deleted"
    end
  end

  describe "Show" do
    test "displays the bio as a profile card with working links", %{conn: conn, data: data} do
      {:ok, show_live, html} = live(conn, ~p"/cms_bios/#{data.cms_bio}")

      assert html =~ data.cms_bio.name
      assert html =~ data.cms_bio.job_title
      assert html =~ data.cms_bio.tag_line
      refute html =~ "Tik Tok"
      assert has_element?(show_live, "#bio-profile img[src='#{data.cms_image.url}']")
      assert has_element?(show_live, "#bio-links a[href='mailto:#{data.cms_bio.email}']")
      assert has_element?(show_live, "#bio-links a[href='tel:0070000007']")
      assert has_element?(show_live, "#bio-links a[href='#{data.cms_bio.instagram}'][target='_blank']", "Instagram")
      assert has_element?(show_live, "#bio-links a[href='#{data.cms_bio.tik_tok}']", "TikTok")
      assert has_element?(show_live, "#bio-links a[href='#{data.cms_bio.linked_in}']", "LinkedIn")
    end

    test "updates bio and returns to show", %{conn: conn, data: data} do
      {:ok, show_live, _html} = live(conn, ~p"/cms_bios/#{data.cms_bio}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit bio")
               |> render_click()
               |> follow_redirect(conn, ~p"/cms_bios/#{data.cms_bio}/edit?return_to=show")

      assert render(form_live) =~ "Edit bio"

      assert form_live
             |> form("#cms_bio-form", cms_bio: %{name: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#cms_bio-form", cms_bio: params_for(:cms_bio, name: "some updated name", slug: "some-updated-slug"))
               |> render_submit()
               |> follow_redirect(conn, ~p"/cms_bios/#{data.cms_bio}")

      html = render(show_live)
      assert html =~ "Bio saved"
      assert html =~ "some updated name"
      assert html =~ "some-updated-slug"
    end
  end
end
