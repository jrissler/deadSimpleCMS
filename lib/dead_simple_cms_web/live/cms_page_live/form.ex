defmodule DeadSimpleCmsWeb.CmsPageLive.Form do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsPage

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      {@page_title}
      <:subtitle>Use this form to manage CMS Pages.</:subtitle>
    </.header>

    <.form for={@form} id="cms_page-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:slug]} type="text" label="Slug" />
      <.input field={@form[:title]} type="text" label="Title" />
      <.input field={@form[:published]} type="checkbox" label="Published" />
      <.input field={@form[:published_at]} type="datetime-local" label="Published at" />
      <footer>
        <.button type="submit" phx-disable-with="Saving..." variant="primary">Save Cms page</.button>
        <.button navigate={return_path(@return_to, @cms_page)}>Cancel</.button>
      </footer>
    </.form>

    <%= if @live_action == :edit do %>
      <div class="mt-10">
        <.header>
          Content Areas
          <:subtitle>Edit slot content here. Layout and rendering are controlled by the host app.</:subtitle>
        </.header>

        <div class="space-y-6">
          <%= for area <- @areas do %>
            <div class="rounded-lg border p-4">
              <div class="mb-3 flex items-center justify-between">
                <div class="min-w-0">
                  <div class="font-semibold truncate">
                    {area.name || "(unnamed)"}
                  </div>
                  <div class="text-sm text-zinc-600">
                    position: {area.position} • visible: {area.visible}
                    {if area.cms_image_id, do: " • image", else: ""}
                  </div>
                </div>
              </div>

              <%= if preview_enabled?() and function_exported?(preview_component_module(), :cms_content_slot, 1) do %>
                <div class="mt-6 border-t pt-6">
                  <div class="mb-3 text-sm font-semibold text-zinc-700">Preview</div>
                  {apply(preview_component_module(), :cms_content_slot, [%{content_area: preview_area(area, @area_forms[area.id])}])}
                </div>
              <% end %>
              <.form for={@area_forms[area.id]} id={"content-area-form-#{area.id}"} phx-change="validate_area" phx-submit="save_area">
                <input type="hidden" name="_id" value={area.id} />

                <div class="grid grid-cols-1 gap-4">
                  <.input field={@area_forms[area.id][:visible]} id={"content-area-#{area.id}-visible"} type="checkbox" label="Visible" />
                  <.input field={@area_forms[area.id][:title]} id={"content-area-#{area.id}-title"} type="text" label="Title" />
                  <.input field={@area_forms[area.id][:subtitle]} id={"content-area-#{area.id}-subtitle"} type="text" label="Subtitle" />

                  <div class="space-y-2 fieldset">
                    <label for={"content-area-#{area.id}-body-md-input"} class="label mb-1">
                      Body (Markdown)
                    </label>

                    <textarea id={"content-area-#{area.id}-body-md-input"} name={@area_forms[area.id][:body_md].name} class="hidden"><%= Phoenix.HTML.Form.input_value(@area_forms[area.id], :body_md) || "" %></textarea>

                    <div id={"content-area-#{area.id}-body-md-editor-wrapper"} phx-update="ignore">
                      <div id={"content-area-#{area.id}-body-md-editor"} phx-hook="EasyMDE" data-target-input-id={"content-area-#{area.id}-body-md-input"} data-initial-value={Phoenix.HTML.Form.input_value(@area_forms[area.id], :body_md) || ""}></div>
                    </div>
                  </div>
                </div>

                <div class="mt-4 flex gap-2">
                  <.button type="submit" phx-disable-with="Saving..." variant="primary">Save Area</.button>
                </div>
              </.form>
            </div>
          <% end %>

          <%= if Enum.empty?(@areas) do %>
            <div class="rounded-lg border border-dashed p-6 text-sm text-zinc-600">
              No content areas exist for this page yet.
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
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
    cms_page = Cms.get_cms_page!(id)

    socket
    |> assign(:page_title, "Edit Cms page")
    |> assign(:cms_page, cms_page)
    |> assign(:areas, cms_page.cms_content_areas)
    |> assign(:area_forms, build_area_forms(cms_page.cms_content_areas))
    |> assign(:form, to_form(Cms.change_cms_page(cms_page)))
  end

  defp apply_action(socket, :new, _params) do
    cms_page = %CmsPage{}

    socket
    |> assign(:page_title, "New Cms page")
    |> assign(:cms_page, cms_page)
    |> assign(:areas, [])
    |> assign(:area_forms, %{})
    |> assign(:form, to_form(Cms.change_cms_page(cms_page)))
  end

  defp build_area_forms(cms_content_area) do
    Enum.reduce(cms_content_area, %{}, fn cms_content_area, forms_by_id ->
      Map.put(forms_by_id, cms_content_area.id, to_form(Cms.change_cms_content_area(cms_content_area)))
    end)
  end

  @impl true
  def handle_event("validate", %{"cms_page" => cms_page_params}, socket) do
    changeset = Cms.change_cms_page(socket.assigns.cms_page, cms_page_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"cms_page" => cms_page_params}, socket) do
    save_cms_page(socket, socket.assigns.live_action, cms_page_params)
  end

  def handle_event("validate_area", %{"_id" => id, "cms_content_area" => params}, socket) do
    content_area = Enum.find(socket.assigns.areas, fn area -> area.id == id end)
    changeset = Cms.change_cms_content_area(content_area, params)
    updated_area_forms = Map.put(socket.assigns.area_forms, content_area.id, to_form(changeset, action: :validate))

    {:noreply, assign(socket, area_forms: updated_area_forms)}
  end

  def handle_event("save_area", %{"_id" => id, "cms_content_area" => params}, socket) do
    content_area = Enum.find(socket.assigns.areas, fn area -> area.id == id end)

    case Cms.update_cms_content_area(content_area, params) do
      {:ok, updated_content_area} ->
        updated_areas = Enum.map(socket.assigns.areas, fn area -> if area.id == updated_content_area.id, do: updated_content_area, else: area end)
        updated_area_forms = Map.put(socket.assigns.area_forms, updated_content_area.id, to_form(Cms.change_cms_content_area(updated_content_area)))

        {:noreply,
         socket
         |> put_flash(:info, "Content area saved")
         |> assign(:areas, updated_areas)
         |> assign(:area_forms, updated_area_forms)}

      {:error, %Ecto.Changeset{} = changeset} ->
        updated_area_forms = Map.put(socket.assigns.area_forms, content_area.id, to_form(changeset))

        {:noreply, assign(socket, area_forms: updated_area_forms)}
    end
  end

  defp save_cms_page(socket, :edit, cms_page_params) do
    case Cms.update_cms_page(socket.assigns.cms_page, cms_page_params) do
      {:ok, cms_page} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cms page updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, cms_page))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_page(socket, :new, cms_page_params) do
    case Cms.create_cms_page(cms_page_params) do
      {:ok, cms_page} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cms page created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, cms_page))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _cms_page), do: DeadSimpleCms.path("/cms_pages")
  defp return_path("show", cms_page), do: DeadSimpleCms.path("/cms_pages/#{cms_page.id}")

  defp preview_component_module do
    Application.get_env(:dead_simple_cms, :preview_components)
  end

  defp preview_enabled? do
    match?(module when is_atom(module), preview_component_module())
  end

  defp preview_area(area, nil), do: area

  defp preview_area(area, form) do
    %{area | visible: input_value(form, :visible, area.visible), title: input_value(form, :title, area.title), subtitle: input_value(form, :subtitle, area.subtitle), body_md: input_value(form, :body_md, area.body_md)}
  end

  defp input_value(form, field, fallback) do
    Phoenix.HTML.Form.input_value(form, field) || fallback
  end
end
