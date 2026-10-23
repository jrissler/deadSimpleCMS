defmodule DeadSimpleCmsWeb.CmsPageTemplateLive.Form do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsPageTemplate
  alias DeadSimpleCmsWeb.ContentAreasEditor

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@page_title} sub_title={@live_action == :edit && @cms_page_template.name} description="A template gives new pages their starting sections, and can add shared sections to every page that uses it.">
      <:action>
        <.button navigate={DeadSimpleCms.path("/cms_page_templates")}>
          <.icon name="hero-arrow-left" class="size-4" /> All templates
        </.button>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="mx-auto max-w-5xl space-y-10 px-4 sm:px-6 lg:px-8">
        <section aria-labelledby="template-settings-heading">
          <div class="overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm">
            <.form for={@form} id="cms_page_template-form" phx-change="validate" phx-submit="save" class="space-y-5 p-6 sm:p-8">
              <h2 id="template-settings-heading" class="text-lg font-semibold tracking-tight text-gray-900">Template settings</h2>

              <.input field={@form[:name]} type="text" label="Template name" />

              <div>
                <.input field={@form[:description]} type="textarea" label="Description" />
                <.hint>What the template is for. Editors see it when choosing a template for a page.</.hint>
              </div>

              <div>
                <.input field={@form[:key]} type="text" label="Key" />
                <.hint>The name the website's code uses for this template, like story_page. {if @live_action == :edit, do: "Changing it can change how pages that use it look.", else: "Ask your developer what to use."}</.hint>
              </div>

              <p :if={@live_action == :edit} class="text-sm text-zinc-600">
                Used by {pages_sentence(@pages)}.
              </p>

              <div class="flex flex-col-reverse gap-3 border-t border-zinc-200 pt-6 sm:flex-row sm:items-center sm:justify-between">
                <button
                  :if={@live_action == :edit}
                  type="button"
                  id="delete-cms-page-template"
                  phx-click="delete"
                  data-confirm={delete_confirm(@cms_page_template, @pages)}
                  class="text-sm font-semibold text-red-600 hover:text-red-500"
                >
                  Delete template
                </button>
                <span :if={@live_action == :new}></span>
                <div class="flex flex-col-reverse gap-3 sm:flex-row">
                  <.button :if={@live_action == :new} navigate={DeadSimpleCms.path("/cms_page_templates")}>Cancel</.button>
                  <.button type="submit" variant="primary" phx-disable-with="Saving...">{if @live_action == :new, do: "Create template", else: "Save template settings"}</.button>
                </div>
              </div>
            </.form>
          </div>
        </section>

        <.live_component :if={@live_action == :edit} module={ContentAreasEditor} id="content-areas" owner={{:template, @cms_page_template.id}} />
      </div>
    </main>
    """
  end

  @impl true
  def mount(params, _session, socket), do: {:ok, apply_action(socket, socket.assigns.live_action, params)}

  defp apply_action(socket, :edit, %{"id" => id}) do
    cms_page_template = Cms.get_cms_page_template!(id)

    socket
    |> assign(:page_title, "Edit template")
    |> assign(:cms_page_template, cms_page_template)
    |> assign(:pages, pages_using(cms_page_template))
    |> assign(:form, to_form(Cms.change_cms_page_template(cms_page_template)))
  end

  defp apply_action(socket, :new, _params) do
    cms_page_template = %CmsPageTemplate{}

    socket
    |> assign(:page_title, "New template")
    |> assign(:cms_page_template, cms_page_template)
    |> assign(:pages, [])
    |> assign(:form, to_form(Cms.change_cms_page_template(cms_page_template)))
  end

  @impl true
  def handle_info({ContentAreasEditor, {:flash, kind, message}}, socket), do: {:noreply, put_flash(socket, kind, message)}

  @impl true
  def handle_event("validate", %{"cms_page_template" => params}, socket) do
    changeset = Cms.change_cms_page_template(socket.assigns.cms_page_template, params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"cms_page_template" => params}, socket) do
    save_cms_page_template(socket, socket.assigns.live_action, params)
  end

  def handle_event("delete", _params, socket) do
    {:ok, _} = Cms.delete_cms_page_template(socket.assigns.cms_page_template)
    {:noreply, socket |> put_flash(:info, "Template \"#{socket.assigns.cms_page_template.name}\" deleted") |> push_navigate(to: DeadSimpleCms.path("/cms_page_templates"))}
  end

  defp save_cms_page_template(socket, :edit, params) do
    case Cms.update_cms_page_template(socket.assigns.cms_page_template, params) do
      {:ok, cms_page_template} ->
        {:noreply, socket |> put_flash(:info, "Template settings saved") |> assign(cms_page_template: cms_page_template, form: to_form(Cms.change_cms_page_template(cms_page_template)))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_page_template(socket, :new, params) do
    case Cms.create_cms_page_template(params) do
      {:ok, cms_page_template} ->
        {:noreply, socket |> put_flash(:info, "Template created. Add its sections below.") |> push_navigate(to: DeadSimpleCms.path("/cms_page_templates/#{cms_page_template.id}/edit"))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp pages_using(template), do: Enum.filter(Cms.list_cms_pages(), &(&1.cms_page_template_id == template.id))

  defp pages_sentence([]), do: "no pages yet"
  defp pages_sentence([page]), do: "1 page (#{page.title})"
  defp pages_sentence(pages), do: "#{length(pages)} pages (#{Enum.map_join(pages, ", ", & &1.title)})"

  defp delete_confirm(template, []), do: "Delete the template \"#{template.name}\"? This can't be undone."

  defp delete_confirm(template, pages),
    do: "Delete the template \"#{template.name}\"? The #{length(pages)} pages using it keep their own sections but lose its shared sections. This can't be undone."
end
