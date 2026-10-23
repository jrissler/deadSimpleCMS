defmodule DeadSimpleCmsWeb.AboutLiveTest do
  @moduledoc false

  use DeadSimpleCmsWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :base_data

  test "explains DSCMS and the AI assistant that's coming", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/about")

    assert html =~ "Your website, without the busywork."
    assert has_element?(view, "#coming-soon", "Claude or ChatGPT")
    assert has_element?(view, "#coming-soon", "Coming in the next few weeks")
    assert has_element?(view, "section", "You stay in charge")
    assert has_element?(view, "a[href='/cms_pages']", "Go to your pages")
  end

  test "the pages list points to it", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/cms_pages")

    assert has_element?(view, "#ai-coming-soon[href='/about#coming-soon']", "Learn more")
  end
end
