defmodule DeadSimpleCmsWeb.CmsImageLive.Form do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsImage

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage cms_image records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="cms_image-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:alt]} type="text" label="Alt" />
        <.input field={@form[:url]} type="text" label="Url" />
        <.input field={@form[:filename]} type="text" label="Filename" />
        <.input field={@form[:content_type]} type="text" label="Filename" />
        <.input field={@form[:size]} type="text" label="Size" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Cms image</.button>
          <.button navigate={return_path(@return_to, @cms_image)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, socket |> assign(:return_to, return_to(params["return_to"])) |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    cms_image = Cms.get_cms_image!(id)
    socket |> assign(:page_title, "Edit Cms image") |> assign(:cms_image, cms_image) |> assign(:form, to_form(Cms.change_cms_image(cms_image)))
  end

  defp apply_action(socket, :new, _params) do
    cms_image = %CmsImage{}
    socket |> assign(:page_title, "New Cms image") |> assign(:cms_image, cms_image) |> assign(:form, to_form(Cms.change_cms_image(cms_image)))
  end

  @impl true
  def handle_event("validate", %{"cms_image" => cms_image_params}, socket) do
    {:noreply, assign(socket, form: to_form(Cms.change_cms_image(socket.assigns.cms_image, cms_image_params), action: :validate))}
  end

  def handle_event("save", %{"cms_image" => cms_image_params}, socket) do
    save_cms_image(socket, socket.assigns.live_action, cms_image_params)
  end

  defp save_cms_image(socket, :edit, cms_image_params) do
    case Cms.update_cms_image(socket.assigns.cms_image, cms_image_params) do
      {:ok, cms_image} ->
        {:noreply, socket |> put_flash(:info, "Cms image updated successfully") |> push_navigate(to: return_path(socket.assigns.return_to, cms_image))}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_image(socket, :new, cms_image_params) do
    case Cms.create_cms_image(cms_image_params) do
      {:ok, cms_image} ->
        {:noreply, socket |> put_flash(:info, "Cms image created successfully") |> push_navigate(to: return_path(socket.assigns.return_to, cms_image))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _cms_image), do: DeadSimpleCms.path("/cms_images")
  defp return_path("show", cms_image), do: DeadSimpleCms.path("/cms_images/#{cms_image.id}")
end
