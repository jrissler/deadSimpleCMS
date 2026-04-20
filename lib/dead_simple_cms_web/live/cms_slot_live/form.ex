defmodule DeadSimpleCmsWeb.CmsSlotLive.Form do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsSlot

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      {@page_title}
      <:subtitle>Use this form to manage CMS Slots.</:subtitle>
    </.header>

    <.form for={@form} id="cms_slot-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:key]} type="text" label="Key" />
      <.input field={@form[:name]} type="text" label="Name" />
      <.input field={@form[:description]} type="textarea" label="Description" />

      <footer class="flex justify-end gap-3 pt-6">
        <.link navigate={return_path(@return_to, @cms_slot)} class="btn btn-primary btn-soft">
          Cancel
        </.link>

        <.button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
          Save Cms slot
        </.button>
      </footer>
    </.form>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    cms_slot = Cms.get_cms_slot!(id)

    socket
    |> assign(:page_title, "Edit Cms slot")
    |> assign(:cms_slot, cms_slot)
    |> assign(:form, to_form(Cms.change_cms_slot(cms_slot)))
  end

  defp apply_action(socket, :new, _params) do
    cms_slot = %CmsSlot{}

    socket
    |> assign(:page_title, "New Cms slot")
    |> assign(:cms_slot, cms_slot)
    |> assign(:form, to_form(Cms.change_cms_slot(cms_slot)))
  end

  @impl true
  def handle_event("validate", %{"cms_slot" => cms_slot_params}, socket) do
    changeset = Cms.change_cms_slot(socket.assigns.cms_slot, cms_slot_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"cms_slot" => cms_slot_params}, socket) do
    save_cms_slot(socket, socket.assigns.live_action, cms_slot_params)
  end

  defp save_cms_slot(socket, :edit, cms_slot_params) do
    case Cms.update_cms_slot(socket.assigns.cms_slot, cms_slot_params) do
      {:ok, cms_slot} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cms slot updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, cms_slot))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_slot(socket, :new, cms_slot_params) do
    case Cms.create_cms_slot(cms_slot_params) do
      {:ok, cms_slot} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cms slot created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, cms_slot))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _cms_slot), do: DeadSimpleCms.path("/cms_slots")
  defp return_path("show", cms_slot), do: DeadSimpleCms.path("/cms_slots/#{cms_slot.id}")
end
