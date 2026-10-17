defmodule DeadSimpleCmsWeb.AdminComponentsOverrideTest do
  use DeadSimpleCmsWeb.ConnCase, async: false

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import DeadSimpleCmsWeb.CoreComponents

  alias DeadSimpleCmsWeb.CoreComponents

  # Overrides content_header, non_list_table, and button (wrapping the
  # built-in); leaves admin_table to fall back to the default.
  defmodule HostComponents do
    use Phoenix.Component

    def content_header(assigns) do
      ~H"""
      <header class="host-header">
        <h1>{@main_title}</h1>
        <p>{@description}</p>
        <div :for={action <- @action} class="host-action">{render_slot(action)}</div>
      </header>
      """
    end

    def non_list_table(assigns) do
      ~H"""
      <table class="host-table" id={@object_name}>
        <tr :for={row <- @row}>{render_slot(row)}</tr>
      </table>
      """
    end

    def button(assigns) do
      CoreComponents.default_button(Map.update!(assigns, :class, &"host-button #{&1}"))
    end
  end

  setup do
    original = Application.get_env(:dead_simple_cms, :admin_components)

    on_exit(fn ->
      if original,
        do: Application.put_env(:dead_simple_cms, :admin_components, original),
        else: Application.delete_env(:dead_simple_cms, :admin_components)
    end)

    :ok
  end

  defp render_header do
    assigns = %{}

    rendered_to_string(~H"""
    <.content_header main_title="Listing CMS Pages" description="Pages own content areas.">
      <:action><a href="/new">Add CMS Page</a></:action>
    </.content_header>
    """)
  end

  defp render_admin_table do
    assigns = %{rows: [%{id: 1, title: "Home"}]}

    rendered_to_string(~H"""
    <.admin_table id="pages" rows={@rows}>
      <:col :let={row} label="Title">{row.title}</:col>
    </.admin_table>
    """)
  end

  defp render_button do
    assigns = %{}

    rendered_to_string(~H"""
    <.button variant="primary" class="extra">Save</.button>
    """)
  end

  describe "without :admin_components" do
    setup do
      Application.delete_env(:dead_simple_cms, :admin_components)
      :ok
    end

    test "renders the built-in components" do
      html = render_header()

      assert html =~ "bg-gradient-to-r from-slate-950"
      assert html =~ "Listing CMS Pages"
      assert html =~ "Add CMS Page"
      refute html =~ "host-header"
      refute render_button() =~ "host-button"
    end
  end

  describe "with :admin_components" do
    setup do
      Application.put_env(:dead_simple_cms, :admin_components, HostComponents)
      :ok
    end

    test "renders the host's override with the same attrs and slots" do
      html = render_header()

      assert html =~ ~s(class="host-header")
      assert html =~ "<h1>Listing CMS Pages</h1>"
      assert html =~ "Pages own content areas."
      assert html =~ ~s(<div class="host-action"><a href="/new">Add CMS Page</a></div>)
      refute html =~ "bg-gradient-to-r from-slate-950"
    end

    test "falls back to the built-in for functions the module doesn't define" do
      html = render_admin_table()

      assert html =~ "min-w-full divide-y divide-gray-300"
      assert html =~ "Home"
    end

    test "lets an override wrap the built-in markup" do
      html = render_button()

      assert html =~ "<button"
      assert html =~ "bg-indigo-600"
      assert html =~ "host-button extra"
      assert html =~ "Save"
    end

    test "is used by the admin pages", %{conn: conn} do
      cms_page = insert(:cms_page, title: "Override Check")

      {:ok, _live, html} = live(conn, ~p"/cms_pages/#{cms_page}")

      assert html =~ ~s(class="host-header")
      assert html =~ "<h1>Viewing CMS Page</h1>"
      assert html =~ ~s(<table class="host-table" id="cms_page">)
      assert html =~ "Override Check"
    end
  end
end
