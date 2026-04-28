defmodule DeadSimpleCmsWeb.CmsPageTemplateLive.Form do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsPageTemplate

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@page_title} sub_title="Admin" description="Page templates define the overall content structure pattern for CMS pages." />

    <main class="pt-2 pb-16 mt-0">
      <div class="max-w-4xl mx-auto sm:px-6 lg:px-8">
        <div class="px-4 sm:px-0">
          <section aria-labelledby="cms-page-template-form-heading">
            <div class="overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm">
              <.form for={@form} id="cms_page_template-form" phx-change="validate" phx-submit="save" class="space-y-6 p-6 sm:p-8">
                <div class="grid grid-cols-1 gap-6">
                  <.input field={@form[:key]} type="text" label="Key" />
                  <.input field={@form[:name]} type="text" label="Name" />
                  <.input field={@form[:description]} type="textarea" label="Description" />
                </div>

                <div class="flex flex-col-reverse gap-3 border-t border-zinc-200 pt-6 sm:flex-row sm:justify-end">
                  <.link navigate={return_path(@return_to, @cms_page_template)} class="inline-flex items-center justify-center rounded-md border border-gray-300 bg-gray-200 px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-300 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-500">
                    Cancel
                  </.link>

                  <.button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
                    Save CMS Page Template
                  </.button>
                </div>
              </.form>
            </div>
          </section>

          <%= if @live_action == :edit do %>
            <section aria-labelledby="cms-page-template-content-areas-heading">
              <.content_header main_title="Content Areas" sub_title="Template Content" description="Edit content areas for this page template.">
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
                      <.form for={@area_forms[area.id]} id={"content-area-form-#{area.id}"} phx-change="validate_area" phx-submit="save_area" class="space-y-6">
                        <input type="hidden" name="_id" value={area.id} />

                        <div class="grid grid-cols-1 gap-4">
                          <.input field={@area_forms[area.id][:name]} id={"content-area-#{area.id}-name"} type="text" label="Name" />
                          <.input field={@area_forms[area.id][:cms_slot_id]} id={"content-area-#{area.id}-cms-slot-id"} type="select" label="Slot" options={[{"Select a slot", nil}] ++ Enum.map(@cms_slots, &{&1.name, &1.id})} />
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
                          <.button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
                            Save Area
                          </.button>
                        </div>
                      </.form>
                    </div>
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
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:cms_slots, Cms.list_cms_slots())
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    cms_page_template = Cms.get_cms_page_template!(id)

    socket
    |> assign(:page_title, "Edit CMS Page Template")
    |> assign(:cms_page_template, cms_page_template)
    |> assign(:areas, cms_page_template.cms_content_areas)
    |> assign(:area_forms, build_area_forms(cms_page_template.cms_content_areas))
    |> assign(:form, to_form(Cms.change_cms_page_template(cms_page_template)))
  end

  defp apply_action(socket, :new, _params) do
    cms_page_template = %CmsPageTemplate{}

    socket
    |> assign(:page_title, "New CMS Page Template")
    |> assign(:cms_page_template, cms_page_template)
    |> assign(:areas, [])
    |> assign(:area_forms, %{})
    |> assign(:form, to_form(Cms.change_cms_page_template(cms_page_template)))
  end

  @impl true
  def handle_event("validate", %{"cms_page_template" => cms_page_template_params}, socket) do
    changeset = Cms.change_cms_page_template(socket.assigns.cms_page_template, cms_page_template_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"cms_page_template" => cms_page_template_params}, socket) do
    save_cms_page_template(socket, socket.assigns.live_action, cms_page_template_params)
  end

  def handle_event("validate_area", %{"_id" => id, "cms_content_area" => params}, socket) do
    content_area = Enum.find(socket.assigns.areas, fn area -> area.id == id end)
    changeset = Cms.change_cms_content_area(content_area, params)
    updated_area_forms = Map.put(socket.assigns.area_forms, content_area.id, to_form(changeset, action: :validate))

    {:noreply, assign(socket, area_forms: updated_area_forms)}
  end

  def handle_event("add_area", _params, socket) do
    attrs = %{cms_page_template_id: socket.assigns.cms_page_template.id, position: Enum.count(socket.assigns.areas) + 1, name: "New Content Area", visible: true, cms_slot_id: List.first(socket.assigns.cms_slots).id}

    case Cms.create_cms_content_area(attrs) do
      {:ok, _content_area} ->
        cms_page_template = Cms.get_cms_page_template!(socket.assigns.cms_page_template.id)

        {:noreply,
         socket
         |> put_flash(:info, "Content area added")
         |> assign(:cms_page_template, cms_page_template)
         |> assign(:areas, cms_page_template.cms_content_areas)
         |> assign(:area_forms, build_area_forms(cms_page_template.cms_content_areas))}

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

  defp build_area_forms(cms_content_area) do
    Enum.reduce(cms_content_area, %{}, fn cms_content_area, forms_by_id ->
      Map.put(forms_by_id, cms_content_area.id, to_form(Cms.change_cms_content_area(cms_content_area)))
    end)
  end

  defp save_cms_page_template(socket, :edit, cms_page_template_params) do
    case Cms.update_cms_page_template(socket.assigns.cms_page_template, cms_page_template_params) do
      {:ok, cms_page_template} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cms page template updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, cms_page_template))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_page_template(socket, :new, cms_page_template_params) do
    case Cms.create_cms_page_template(cms_page_template_params) do
      {:ok, cms_page_template} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cms page template created successfully")
         |> push_navigate(to: DeadSimpleCms.path("/cms_page_templates/#{cms_page_template.id}/edit"))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _cms_page_template), do: DeadSimpleCms.path("/cms_page_templates")
  defp return_path("show", cms_page_template), do: DeadSimpleCms.path("/cms_page_templates/#{cms_page_template.id}")
end
