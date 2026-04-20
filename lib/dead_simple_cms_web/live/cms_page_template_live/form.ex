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

                  <.button phx-disable-with="Saving..." variant="primary">
                    Save CMS Page Template
                  </.button>
                </div>
              </.form>
            </div>
          </section>
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
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    cms_page_template = Cms.get_cms_page_template!(id)

    socket
    |> assign(:page_title, "Edit CMS Page Template")
    |> assign(:cms_page_template, cms_page_template)
    |> assign(:form, to_form(Cms.change_cms_page_template(cms_page_template)))
  end

  defp apply_action(socket, :new, _params) do
    cms_page_template = %CmsPageTemplate{}

    socket
    |> assign(:page_title, "New CMS Page Template")
    |> assign(:cms_page_template, cms_page_template)
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
         |> push_navigate(to: return_path(socket.assigns.return_to, cms_page_template))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _cms_page_template), do: DeadSimpleCms.path("/cms_page_templates")
  defp return_path("show", cms_page_template), do: DeadSimpleCms.path("/cms_page_templates/#{cms_page_template.id}")
end
