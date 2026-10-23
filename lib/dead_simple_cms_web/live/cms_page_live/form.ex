defmodule DeadSimpleCmsWeb.CmsPageLive.Form do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsPage
  alias DeadSimpleCmsWeb.ContentAreasEditor

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@page_title} sub_title={@live_action == :edit && @cms_page.title} description={header_description(@live_action)}>
      <:action>
        <.button navigate={DeadSimpleCms.path("/cms_pages")}>
          <.icon name="hero-arrow-left" class="size-4" /> All pages
        </.button>
        <.preview_page_link :if={@live_action == :edit} cms_page={@cms_page} />
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="mx-auto max-w-5xl space-y-10 px-4 sm:px-6 lg:px-8">
        <section aria-labelledby="page-settings-heading">
          <div class="overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm">
            <.form for={@form} id="cms_page-form" phx-change="validate" phx-submit="save" class="space-y-8 p-6 sm:p-8">
              <div class="space-y-5">
                <div class="flex flex-wrap items-center justify-between gap-3">
                  <h2 id="page-settings-heading" tabindex="-1" class="text-lg font-semibold tracking-tight text-gray-900 focus:outline-none">Page settings</h2>
                  <.status_badge :if={@live_action == :edit} tone={if @cms_page.published, do: :good, else: :muted}>
                    {if @cms_page.published, do: "Live", else: "Draft"}
                  </.status_badge>
                </div>

                <.input field={@form[:title]} type="text" label="Page title" />

                <div>
                  <.input field={@form[:slug]} type="text" label="Page address" placeholder="about-us" />
                  <.hint>The end of the page's web address, in lowercase words joined by dashes. {if @live_action == :new, do: "Filled in from the title if you leave it blank.", else: "Changing it breaks links people already have."}</.hint>
                </div>

                <div class="rounded-lg border border-zinc-200 bg-zinc-50 p-4">
                  <.input field={@form[:published]} type="checkbox" label="Published: show this page on the site" />
                  <.hint>Unpublished pages are drafts. Only editors can see them, with Preview Page.</.hint>
                </div>

                <div>
                  <.input field={@form[:published_at]} type="datetime-local" label="Publish date" />
                  <.hint>Optional. Set to today when you first publish, if left blank.</.hint>
                </div>

                <div>
                  <.input field={@form[:cms_page_template_id]} type="select" label="Template" options={[{"None", ""}] ++ Enum.map(@cms_page_templates, &{&1.name, &1.id})} />
                  <.hint>{template_hint(@live_action)}</.hint>
                </div>
              </div>

              <div class="space-y-5 border-t border-zinc-200 pt-8">
                <div>
                  <h2 id="page-seo-heading" tabindex="-1" class="text-lg font-semibold tracking-tight text-gray-900 focus:outline-none">Search and sharing</h2>
                  <p class="mt-1 text-sm text-gray-600">Optional. How the page appears in Google and when someone shares a link to it.</p>
                </div>

                <div>
                  <.input field={@form[:meta_title]} type="text" label="Search title" />
                  <.hint>{char_count(@form, :meta_title)} characters. Aim for 60 or fewer. Uses the page title when blank.</.hint>
                </div>

                <div>
                  <.input field={@form[:meta_description]} type="textarea" label="Search description" />
                  <.hint>{char_count(@form, :meta_description)} characters. Aim for 150–160: one or two sentences that make someone want to click.</.hint>
                </div>

                <div class="flex flex-col gap-4 sm:flex-row sm:items-end">
                  <div class="min-w-0 flex-1">
                    <.input field={@form[:og_image_id]} type="select" label="Share image" options={[{"None", ""}] ++ Enum.map(@cms_images, &{image_label(&1), &1.id})} />
                    <.hint>Shown when the page is shared on social media or in messages.</.hint>
                  </div>
                  <img :if={selected_image(@form, @cms_images)} src={Cms.image_url(selected_image(@form, @cms_images))} alt="" class="h-20 w-32 rounded-lg object-cover ring-1 ring-zinc-200" />
                </div>

                <div>
                  <.input field={@form[:noindex]} type="checkbox" label="Hide from search engines" />
                  <.hint>Keeps the page out of Google and the sitemap. Leave this off for most pages.</.hint>
                </div>
              </div>

              <div class="flex flex-col-reverse gap-3 border-t border-zinc-200 pt-6 sm:flex-row sm:items-center sm:justify-between">
                <button
                  :if={@live_action == :edit}
                  type="button"
                  id="delete-cms-page"
                  phx-click="delete"
                  data-confirm={"Delete the page \"#{@cms_page.title}\" and its #{length(@cms_page.cms_content_areas)} sections? This can't be undone."}
                  class="text-sm font-semibold text-red-600 hover:text-red-500"
                >
                  Delete page
                </button>
                <span :if={@live_action == :new}></span>
                <div class="flex flex-col-reverse gap-3 sm:flex-row">
                  <.button :if={@live_action == :new} navigate={DeadSimpleCms.path("/cms_pages")}>Cancel</.button>
                  <.button type="submit" variant="primary" phx-disable-with="Saving...">{if @live_action == :new, do: "Create page", else: "Save page settings"}</.button>
                </div>
              </div>
            </.form>
          </div>
        </section>

        <.live_component :if={@live_action == :edit} module={ContentAreasEditor} id="content-areas" owner={{:page, @cms_page.id}} />
      </div>
    </main>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, socket |> assign(:cms_page_templates, Cms.list_cms_page_templates()) |> assign(:cms_images, Cms.list_cms_images()) |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    cms_page = Cms.get_cms_page!(id)

    socket
    |> assign(:page_title, "Edit page")
    |> assign(:cms_page, cms_page)
    |> assign(:form, to_form(Cms.change_cms_page(cms_page)))
  end

  defp apply_action(socket, :new, _params) do
    cms_page = %CmsPage{published: false}

    socket
    |> assign(:page_title, "New page")
    |> assign(:cms_page, cms_page)
    |> assign(:form, to_form(Cms.change_cms_page(cms_page)))
  end

  @impl true
  def handle_info({ContentAreasEditor, {:flash, kind, message}}, socket), do: {:noreply, put_flash(socket, kind, message)}

  @impl true
  def handle_event("validate", %{"cms_page" => params}, socket) do
    changeset = Cms.change_cms_page(socket.assigns.cms_page, prepare(params, socket.assigns.live_action))
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"cms_page" => params}, socket) do
    save_cms_page(socket, socket.assigns.live_action, prepare(params, socket.assigns.live_action))
  end

  def handle_event("delete", _params, socket) do
    {:ok, _} = Cms.delete_cms_page(socket.assigns.cms_page)
    {:noreply, socket |> put_flash(:info, "Page \"#{socket.assigns.cms_page.title}\" deleted") |> push_navigate(to: DeadSimpleCms.path("/cms_pages"))}
  end

  defp save_cms_page(socket, :edit, params) do
    case Cms.update_cms_page(socket.assigns.cms_page, params) do
      {:ok, _cms_page} ->
        cms_page = Cms.get_cms_page!(socket.assigns.cms_page.id)
        {:noreply, socket |> put_flash(:info, "Page settings saved") |> assign(cms_page: cms_page, form: to_form(Cms.change_cms_page(cms_page)))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_page(socket, :new, params) do
    case Cms.create_cms_page(params) do
      {:ok, cms_page} ->
        socket =
          case Cms.copy_template_areas_to_page(cms_page) do
            {:ok, 0} -> put_flash(socket, :info, "Page created. Add its sections below.")
            {:ok, copied} -> put_flash(socket, :info, "Page created with #{copied} starter sections from its template")
            {:error, _area_changeset} -> put_flash(socket, :error, "Page created, but its template's sections couldn't be copied")
          end

        {:noreply, push_navigate(socket, to: DeadSimpleCms.path("/cms_pages/#{cms_page.id}/edit"))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # A new page's address is filled in from its title until one is typed. A
  # page published without a date gets today's.
  defp prepare(params, action) do
    params
    |> then(fn params -> if action == :new and blank?(params["slug"]) and not blank?(params["title"]), do: Map.put(params, "slug", params["title"]), else: params end)
    |> then(fn params -> if params["published"] == "true" and blank?(params["published_at"]), do: Map.put(params, "published_at", DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()), else: params end)
  end

  defp blank?(value), do: value in [nil, ""]

  defp header_description(:new), do: "Name the page and choose a template. You'll add its sections next."
  defp header_description(:edit), do: "Page settings and search details first, then the sections that make up the page."

  defp template_hint(:new), do: "Optional. A new page starts with a copy of the template's sections, ready to edit."
  defp template_hint(:edit), do: "Changing the template later doesn't change this page's sections. Shared template sections (like a closing call to action) follow the template."

  defp image_label(image), do: image.alt || image.filename

  defp selected_image(form, images) do
    id = Phoenix.HTML.Form.input_value(form, :og_image_id)
    Enum.find(images, &(to_string(&1.id) == to_string(id)))
  end

  defp char_count(form, field), do: form |> Phoenix.HTML.Form.input_value(field) |> to_string() |> String.length()
end
