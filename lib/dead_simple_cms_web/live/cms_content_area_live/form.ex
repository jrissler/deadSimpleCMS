defmodule DeadSimpleCmsWeb.CmsContentAreaLive.Form do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsContentArea

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage cms_content_area records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="cms_content_area-form" phx-change="validate" phx-submit="save">
        <.input
          field={@form[:cms_page_id]}
          type="select"
          label="Page"
          options={@pages}
          prompt="Select a page"
        />
        <.input field={@form[:cms_image_id]} type="text" />
        <.input field={@form[:position]} type="number" label="Position" />
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:visible]} type="checkbox" label="Visible" />
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:subtitle]} type="text" label="Subtitle" />
        <.input field={@form[:body_md]} type="textarea" label="Body md" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Cms content area</.button>
          <.button navigate={return_path(@return_to, @cms_content_area)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    pages = Cms.list_cms_pages() |> Enum.map(&{&1.title, &1.id})

    {:ok,
     socket
     |> assign(:pages, pages)
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    cms_content_area = Cms.get_cms_content_area!(id)

    socket
    |> assign(:page_title, "Edit Cms content area")
    |> assign(:cms_content_area, cms_content_area)
    |> assign(:form, to_form(Cms.change_cms_content_area(cms_content_area)))
  end

  defp apply_action(socket, :new, _params) do
    cms_content_area = %CmsContentArea{}

    socket
    |> assign(:page_title, "New Cms content area")
    |> assign(:cms_content_area, cms_content_area)
    |> assign(:form, to_form(Cms.change_cms_content_area(cms_content_area)))
  end

  @impl true
  def handle_event("validate", %{"cms_content_area" => cms_content_area_params}, socket) do
    {:noreply, assign(socket, form: to_form(Cms.change_cms_content_area(socket.assigns.cms_content_area, cms_content_area_params), action: :validate))}
  end

  def handle_event("save", %{"cms_content_area" => cms_content_area_params}, socket) do
    save_cms_content_area(socket, socket.assigns.live_action, cms_content_area_params)
  end

  defp save_cms_content_area(socket, :edit, cms_content_area_params) do
    case Cms.update_cms_content_area(socket.assigns.cms_content_area, cms_content_area_params) do
      {:ok, cms_content_area} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cms content area updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, cms_content_area))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_content_area(socket, :new, cms_content_area_params) do
    case Cms.create_cms_content_area(cms_content_area_params) do
      {:ok, cms_content_area} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cms content area created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, cms_content_area))}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _cms_content_area), do: DeadSimpleCms.path("/cms_content_areas")
  defp return_path("show", cms_content_area), do: DeadSimpleCms.path("/cms_content_areas/#{cms_content_area.id}")
end
