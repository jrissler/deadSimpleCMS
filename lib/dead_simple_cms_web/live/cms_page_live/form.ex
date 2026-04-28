defmodule DeadSimpleCmsWeb.CmsPageLive.Form do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsPage

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@page_title} sub_title="Admin" description="Edit CMS Page Settings">
      <:action>
        <.link patch={DeadSimpleCms.path("/cms_pages")} class="flex items-center justify-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          <.icon name="hero-pencil" class="-ml-0.5 mr-1 h-5 w-5" /> All CMS Pages
        </.link>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="max-w-4xl mx-auto sm:px-6 lg:px-8">
        <div class="px-4 sm:px-0 space-y-10">
          <section aria-labelledby="cms-page-form-heading">
            <div class="overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm">
              <.form for={@form} id="cms_page-form" phx-change="validate" phx-submit="save" class="space-y-6 p-6 sm:p-8">
                <div class="grid grid-cols-1 gap-6">
                  <.input field={@form[:slug]} type="text" label="Slug" />
                  <.input field={@form[:title]} type="text" label="Title" />
                  <.input field={@form[:published]} type="checkbox" label="Published" />
                  <.input field={@form[:published_at]} type="datetime-local" label="Published at" />
                  <.input field={@form[:cms_page_template_id]} type="select" label="Page Template (Optional)" options={[{"Select a template", nil}] ++ Enum.map(@cms_page_templates, &{&1.name, &1.id})} />
                </div>

                <div class="flex flex-col-reverse gap-3 border-t border-zinc-200 pt-6 sm:flex-row sm:justify-end">
                  <.link navigate={return_path(@return_to, @cms_page)} class="inline-flex items-center justify-center rounded-md border border-gray-300 bg-gray-200 px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-300 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-500">
                    Cancel
                  </.link>

                  <.button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
                    Save CMS Page
                  </.button>
                </div>
              </.form>
            </div>
          </section>

          <%= if @live_action == :edit do %>
            <section aria-labelledby="cms-page-content-areas-heading">
              <.content_header main_title="Content Areas" sub_title="Page Content" description="Edit content areas for this CMS page.">
                <:action>
                  <button type="button" phx-click="add_area" class="btn btn-primary">
                    Add Content Area
                  </button>
                </:action>
              </.content_header>

              <div class="space-y-6 mt-6">
                <%= for area <- @areas do %>
                  <div class="overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm">
                    <div class="border-b border-zinc-200 px-6 py-4">
                      <div class="min-w-0">
                        <div class="truncate text-base font-semibold text-zinc-900">
                          {area.name || "(unnamed)"}
                        </div>

                        <div class="mt-1 text-sm text-zinc-600">
                          position: {area.position} • visible: {area.visible}
                          {if area.cms_slot_id, do: " • slot", else: ""}
                        </div>
                      </div>
                    </div>

                    <div class="p-6 sm:p-8">
                      <%= if preview_enabled?() and function_exported?(preview_component_module(), :cms_content_slot, 1) do %>
                        <div class="mb-6 rounded-2xl border border-zinc-200 bg-zinc-50 p-6">
                          <div class="mb-4 text-xs font-semibold uppercase tracking-[0.14em] text-zinc-500">
                            Preview
                          </div>

                          {apply(preview_component_module(), :cms_content_slot, [%{content_area: preview_area(area, @area_forms[area.id], @cms_slots)}])}
                        </div>
                      <% end %>

                      <.form for={@area_forms[area.id]} id={"content-area-form-#{area.id}"} phx-change="validate_area" phx-submit="save_area" class="space-y-6">
                        <input type="hidden" name="_id" value={area.id} />

                        <div class="grid grid-cols-1 gap-4">
                          <.input field={@area_forms[area.id][:name]} id={"content-area-#{area.id}-name"} type="text" label="Name" />
                          <.input field={@area_forms[area.id][:cms_slot_id]} id={"content-area-#{area.id}-cms-slot-id"} type="select" label="Slot" options={[{"Select a slot", nil}] ++ Enum.map(@cms_slots, &{&1.name, &1.id})} />
                          <.input field={@area_forms[area.id][:visible]} id={"content-area-#{area.id}-visible"} type="checkbox" label="Visible" />
                          <.input field={@area_forms[area.id][:position]} id={"content-area-#{area.id}-position"} type="number" label="Position" />
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
                          <.button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
                            Save Area
                          </.button>
                        </div>
                      </.form>
                    </div>
                  </div>
                <% end %>

                <%= if Enum.empty?(@areas) do %>
                  <div class="rounded-2xl border border-dashed border-zinc-300 bg-white p-6 text-sm text-zinc-600 shadow-sm">
                    No content areas exist for this page yet.
                  </div>
                <% end %>
              </div>
            </section>
          <% end %>
        </div>
      </div>
    </main>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, socket |> assign(:return_to, return_to(params["return_to"])) |> assign(:cms_page_templates, Cms.list_cms_page_templates()) |> assign(:cms_slots, Cms.list_cms_slots()) |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    cms_page = Cms.get_cms_page!(id)
    areas = Enum.sort_by(cms_page.cms_content_areas, & &1.position)

    socket
    |> assign(:page_title, "Edit CMS Page")
    |> assign(:cms_page, cms_page)
    |> assign(:areas, areas)
    |> assign(:area_forms, build_area_forms(areas))
    |> assign(:form, to_form(Cms.change_cms_page(cms_page)))
  end

  defp apply_action(socket, :new, _params) do
    cms_page = %CmsPage{}

    socket
    |> assign(:page_title, "New CMS Page")
    |> assign(:cms_page, cms_page)
    |> assign(:areas, [])
    |> assign(:area_forms, %{})
    |> assign(:form, to_form(Cms.change_cms_page(cms_page)))
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

  def handle_event("add_area", _params, socket) do
    attrs = %{cms_page_id: socket.assigns.cms_page.id, position: Enum.count(socket.assigns.areas) + 1, name: "New Content Area", visible: true, cms_slot_id: List.first(socket.assigns.cms_slots).id}

    case Cms.create_cms_content_area(attrs) do
      {:ok, _content_area} ->
        cms_page = Cms.get_cms_page!(socket.assigns.cms_page.id)

        {:noreply, socket |> put_flash(:info, "Content area added") |> assign(:cms_page, cms_page) |> assign(:areas, cms_page.cms_content_areas) |> assign(:area_forms, build_area_forms(cms_page.cms_content_areas))}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:noreply, put_flash(socket, :error, "Content area could not be added")}
    end
  end

  def handle_event("save_area", %{"_id" => id, "cms_content_area" => params}, socket) do
    content_area = Enum.find(socket.assigns.areas, fn area -> area.id == id end)

    case Cms.update_cms_content_area(content_area, params) do
      {:ok, updated_content_area} ->
        updated_areas = Enum.map(socket.assigns.areas, fn area -> if area.id == updated_content_area.id, do: updated_content_area, else: area end)
        updated_area_forms = Map.put(socket.assigns.area_forms, updated_content_area.id, to_form(Cms.change_cms_content_area(updated_content_area)))

        {:noreply, socket |> put_flash(:info, "Content area saved") |> assign(:areas, updated_areas) |> assign(:area_forms, updated_area_forms)}

      {:error, %Ecto.Changeset{} = changeset} ->
        updated_area_forms = Map.put(socket.assigns.area_forms, content_area.id, to_form(changeset))
        {:noreply, assign(socket, area_forms: updated_area_forms)}
    end
  end

  defp build_area_forms(cms_content_areas) do
    Enum.reduce(cms_content_areas, %{}, fn cms_content_area, forms_by_id -> Map.put(forms_by_id, cms_content_area.id, to_form(Cms.change_cms_content_area(cms_content_area))) end)
  end

  defp save_cms_page(socket, :edit, cms_page_params) do
    case Cms.update_cms_page(socket.assigns.cms_page, cms_page_params) do
      {:ok, cms_page} ->
        {:noreply, socket |> put_flash(:info, "Cms page updated successfully") |> push_navigate(to: return_path(socket.assigns.return_to, cms_page))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_page(socket, :new, cms_page_params) do
    case Cms.create_cms_page(cms_page_params) do
      {:ok, cms_page} ->
        {:noreply, socket |> put_flash(:info, "Cms page created successfully") |> push_navigate(to: return_path(socket.assigns.return_to, cms_page))}

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

  defp preview_area(area, nil, _cms_slots), do: area

  defp preview_area(area, form, cms_slots) do
    cms_slot_id = input_value(form, :cms_slot_id, area.cms_slot_id)

    %{area | name: input_value(form, :name, area.name), position: input_value(form, :position, area.position), visible: input_value(form, :visible, area.visible), cms_slot_id: cms_slot_id, cms_slot: Enum.find(cms_slots, fn slot -> slot.id == cms_slot_id end) || area.cms_slot, title: input_value(form, :title, area.title), subtitle: input_value(form, :subtitle, area.subtitle), body_md: input_value(form, :body_md, area.body_md)}
  end

  defp input_value(form, field, fallback) do
    Phoenix.HTML.Form.input_value(form, field) || fallback
  end
end
