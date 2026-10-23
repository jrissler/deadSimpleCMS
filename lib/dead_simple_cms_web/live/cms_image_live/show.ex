defmodule DeadSimpleCmsWeb.CmsImageLive.Show do
  @moduledoc """
  One image at a glance: the picture itself, its description and caption, file
  details and every place on the site that uses it, with links to edit or delete.

  Also holds the small helpers the image screens share (usage lists, the delete
  confirmation, friendly file sizes).
  """
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@cms_image.filename} sub_title="Image" description={@cms_image.alt || "No description yet"}>
      <:action>
        <.button navigate={DeadSimpleCms.path("/cms_images")}>
          <.icon name="hero-arrow-left" class="size-4" /> All images
        </.button>
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_images/#{@cms_image.id}/edit?return_to=show")}>
          <.icon name="hero-pencil" class="size-4" /> Edit image
        </.button>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="mx-auto grid max-w-6xl gap-6 px-4 sm:px-6 lg:grid-cols-[minmax(0,1fr)_20rem] lg:px-8">
        <div class="space-y-6">
          <section aria-label="Image" class="rounded-2xl border border-zinc-200 bg-white p-4 shadow-sm">
            <div class="flex items-center justify-center rounded-xl bg-zinc-100">
              <img id="cms-image-preview" src={Cms.image_url(@cms_image)} alt={@cms_image.alt || ""} class="max-h-[36rem] w-auto max-w-full rounded-xl object-contain" />
            </div>
            <p class="mt-3 text-right text-sm">
              <.link href={Cms.image_url(@cms_image)} target="_blank" rel="noopener" class="font-semibold text-zinc-700 hover:text-zinc-900">
                Open full size <.icon name="hero-arrow-top-right-on-square" class="size-4" />
              </.link>
            </p>
          </section>

          <section aria-labelledby="image-usage-heading" class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
            <h2 id="image-usage-heading" class="text-base font-semibold text-zinc-900">Used on</h2>
            <ul :if={@usage_items != []} id="image-usage" class="mt-4 divide-y divide-zinc-100">
              <li :for={item <- @usage_items} class="flex items-center justify-between gap-4 py-3">
                <div class="min-w-0">
                  <p class="truncate text-sm font-semibold text-zinc-900">{item.title}</p>
                  <p class="text-xs text-zinc-500">{item.kind}</p>
                </div>
                <.link :if={item.path} navigate={item.path} class="shrink-0 text-sm font-semibold text-zinc-700 hover:text-zinc-900">
                  {item.link_label}
                </.link>
              </li>
            </ul>
            <p :if={@usage_items == []} class="mt-4 text-sm text-zinc-500">
              Not used anywhere yet. Choose it in a section, bio or page share image to put it on the site.
            </p>
          </section>
        </div>

        <aside class="space-y-6">
          <div class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
            <h2 class="text-base font-semibold text-zinc-900">About this image</h2>
            <dl class="mt-4 space-y-4 text-sm">
              <div>
                <dt class="text-zinc-500">Description (alt text)</dt>
                <dd class="mt-1 text-zinc-900">
                  <span :if={present?(@cms_image.alt)}>{@cms_image.alt}</span>
                  <.status_badge :if={!present?(@cms_image.alt)} tone={:warning}>Needs a description</.status_badge>
                </dd>
              </div>
              <div>
                <dt class="text-zinc-500">Caption</dt>
                <dd class="mt-1 space-y-1 text-zinc-900">
                  <p>{if present?(@cms_image.caption), do: @cms_image.caption, else: "None"}</p>
                  <.status_badge :if={placeholder?(@cms_image)} tone={:warning}>Placeholder image</.status_badge>
                </dd>
              </div>
              <div :if={dimensions(@cms_image)}>
                <dt class="text-zinc-500">Dimensions</dt>
                <dd class="mt-1 text-zinc-900">{dimensions(@cms_image)}</dd>
              </div>
              <div>
                <dt class="text-zinc-500">File</dt>
                <dd class="mt-1 text-zinc-900">{file_summary(@cms_image)}</dd>
              </div>
              <div>
                <dt class="text-zinc-500">Uploaded</dt>
                <dd class="mt-1 text-zinc-900">{friendly_date(@cms_image.inserted_at)}</dd>
              </div>
              <div :if={@cms_image.updated_at != @cms_image.inserted_at}>
                <dt class="text-zinc-500">Last changed</dt>
                <dd class="mt-1 text-zinc-900">{friendly_date(@cms_image.updated_at)}</dd>
              </div>
            </dl>
          </div>

          <div class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
            <h2 class="text-base font-semibold text-zinc-900">Delete</h2>
            <p class="mt-1 text-sm text-zinc-500">{usage_summary(@usage_items)}</p>
            <.button id="delete-cms-image" variant="danger" class="mt-4" phx-click="delete" data-confirm={delete_confirmation(@cms_image, @usage_items)}>
              <.icon name="hero-trash" class="size-4" /> Delete image
            </.button>
          </div>
        </aside>
      </div>
    </main>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    cms_image = Cms.get_cms_image!(id)

    {:ok,
     socket
     |> assign(:page_title, cms_image.filename)
     |> assign(:cms_image, cms_image)
     |> assign(:usage_items, usage_items(Cms.image_usage(cms_image)))}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    case delete_image(socket.assigns.cms_image) do
      {:ok, message} -> {:noreply, socket |> put_flash(:info, message) |> push_navigate(to: DeadSimpleCms.path("/cms_images"))}
      {:error, message} -> {:noreply, put_flash(socket, :error, message)}
    end
  end

  ## Shared by the image screens

  @doc false
  # Deletes an image, returning the flash message to show either way.
  def delete_image(cms_image) do
    case Cms.delete_cms_image(cms_image) do
      {:ok, _} -> {:ok, "Image \"#{cms_image.filename}\" deleted"}
      {:error, _} -> {:error, "Couldn't delete \"#{cms_image.filename}\". Try again."}
    end
  end

  @doc false
  # Turns `Cms.image_usage/1`'s `%{areas:, bios:, pages:}` into one list of
  # `%{title, kind, path, link_label, short}`, where `short` is the name used in
  # the delete confirmation, like "About (hero)".
  def usage_items(%{areas: areas, bios: bios, pages: pages}) do
    Enum.map(areas, &area_item/1) ++ Enum.map(bios, &bio_item/1) ++ Enum.map(pages, &share_item/1)
  end

  defp area_item(area) do
    section = area.title || area.name

    case area do
      %{cms_page: %{id: id, title: title}} ->
        %{title: title, kind: "Section: #{section}", path: DeadSimpleCms.path("/cms_pages/#{id}/edit"), link_label: "Edit page", short: "#{title} (#{section})"}

      %{cms_page_template: %{id: id, name: name}} ->
        %{title: "#{name} template", kind: "Section: #{section}", path: DeadSimpleCms.path("/cms_page_templates/#{id}/edit"), link_label: "Edit template", short: "#{name} template (#{section})"}

      _ ->
        %{title: section, kind: "Section", path: nil, link_label: nil, short: section}
    end
  end

  defp bio_item(bio), do: %{title: bio.name, kind: "Bio photo", path: DeadSimpleCms.path("/cms_bios/#{bio.id}"), link_label: "Open bio", short: "#{bio.name} (bio)"}

  defp share_item(page),
    do: %{title: page.title, kind: "Share image for search and social", path: DeadSimpleCms.path("/cms_pages/#{page.id}/edit"), link_label: "Edit page", short: "#{page.title} (share image)"}

  @doc false
  def usage_summary([]), do: "Not used anywhere."
  def usage_summary([_]), do: "Used in 1 place."
  def usage_summary(items), do: "Used in #{length(items)} places."

  @doc false
  def delete_confirmation(cms_image, []), do: "Delete the image \"#{cms_image.filename}\"? Not used anywhere, so nothing else changes. This can't be undone."

  def delete_confirmation(cms_image, items) do
    names = Enum.map_join(items, ", ", & &1.short)
    left = if length(items) == 1, do: "It'll be left without an image.", else: "They'll be left without an image."
    "Delete the image \"#{cms_image.filename}\"? #{String.trim_trailing(usage_summary(items), ".")}: #{names}. #{left} This can't be undone."
  end

  @doc false
  # Captions like "Placeholder: replace with a photo of the crew" mark images to replace.
  def placeholder?(%{caption: caption}) when is_binary(caption), do: caption =~ ~r/placeholder/i
  def placeholder?(_), do: false

  @doc false
  def present?(value), do: is_binary(value) and String.trim(value) != ""

  @doc false
  def human_size(nil), do: nil
  def human_size(bytes) when bytes < 1024, do: "#{bytes} bytes"
  def human_size(bytes) when bytes < 1024 * 1024, do: "#{round(bytes / 1024)} KB"
  def human_size(bytes), do: "#{:erlang.float_to_binary(bytes / (1024 * 1024), decimals: 1)} MB"

  @doc false
  # "image/jpeg" -> "JPEG", "image/svg+xml" -> "SVG".
  def file_type(nil), do: nil
  def file_type(content_type), do: content_type |> String.split("/") |> List.last() |> String.split("+") |> hd() |> String.upcase()

  @doc false
  # "JPEG · 1.2 MB"
  def file_summary(cms_image), do: [file_type(cms_image.content_type), human_size(cms_image.size)] |> Enum.reject(&is_nil/1) |> Enum.join(" · ")

  @doc false
  def dimensions(%{width: w, height: h}) when is_integer(w) and is_integer(h), do: "#{w} × #{h} pixels"
  def dimensions(_), do: nil
end
