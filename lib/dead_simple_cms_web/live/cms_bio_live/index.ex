defmodule DeadSimpleCmsWeb.CmsBioLive.Index do
  @moduledoc "All bios, with photo, job title and whether each is shown on the site."
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.SpecialContent

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title="Bios" sub_title="Website content" description="Profiles of the people behind the site. Click a bio to edit it.">
      <:action>
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_bios/new")}>
          <.icon name="hero-plus" class="size-4" /> New bio
        </.button>
      </:action>
    </.content_header>

    <.admin_table
      id="cms_bios"
      rows={@streams.cms_bios}
      row_click={fn {_id, cms_bio} -> JS.navigate(DeadSimpleCms.path("/cms_bios/#{cms_bio.id}/edit")) end}
      empty_title="No bios yet"
      empty_description="Add a bio for each person you want to feature on the site."
    >
      <:col :let={{_id, cms_bio}} label="Person">
        <span class="flex items-center gap-3">
          <img :if={cms_bio.cms_image} src={cms_bio.cms_image.url} alt="" class="h-10 w-10 shrink-0 rounded-full object-cover ring-1 ring-zinc-200" />
          <span :if={!cms_bio.cms_image} class="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-zinc-100 text-zinc-400 ring-1 ring-zinc-200">
            <.icon name="hero-user" class="size-5" />
          </span>
          <span class="min-w-0">
            <span class="block">{cms_bio.name}</span>
            <span :if={cms_bio.job_title} class="block text-xs font-normal text-zinc-500">{cms_bio.job_title}</span>
          </span>
        </span>
      </:col>
      <:col :let={{_id, cms_bio}} label="Status">
        <.status_badge tone={if cms_bio.visible, do: :good, else: :muted}>{if cms_bio.visible, do: "Shown", else: "Hidden"}</.status_badge>
      </:col>
      <:col :let={{_id, cms_bio}} label="Updated">{friendly_date(cms_bio.updated_at)}</:col>

      <:action :let={{_id, cms_bio}}>
        <.link navigate={DeadSimpleCms.path("/cms_bios/#{cms_bio.id}/edit")}>Edit</.link>
      </:action>
      <:action :let={{_id, cms_bio}}>
        <.link navigate={DeadSimpleCms.path("/cms_bios/#{cms_bio.id}")}>View</.link>
      </:action>
      <:action :let={{_id, cms_bio}}>
        <.link phx-click={JS.push("delete", value: %{id: cms_bio.id})} data-confirm={"Delete the bio for \"#{cms_bio.name}\"? This can't be undone."}>
          Delete
        </.link>
      </:action>
    </.admin_table>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    bios = Enum.sort_by(SpecialContent.list_cms_bios(), &String.downcase(&1.name || ""))

    {:ok,
     socket
     |> assign(:page_title, "Bios")
     |> stream(:cms_bios, bios)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cms_bio = SpecialContent.get_cms_bio!(id)

    case SpecialContent.delete_cms_bio(cms_bio) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "Bio \"#{cms_bio.name}\" deleted") |> stream_delete(:cms_bios, cms_bio)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "The bio for \"#{cms_bio.name}\" couldn't be deleted. Try again.")}
    end
  end
end
