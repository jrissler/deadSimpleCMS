defmodule DeadSimpleCmsWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use DeadSimpleCmsWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  # slot :inner_block, required: true

  def app(assigns) do
    # Everyday editing first; templates, section types and the raw section list are setup.
    assigns =
      assigns
      |> Map.put(:content_links, [{"Pages", "/cms_pages"}, {"Images", "/cms_images"}, {"Bios", "/cms_bios"}, {"Testimonials", "/cms_testimonials"}])
      |> Map.put(:setup_links, [{"Templates", "/cms_page_templates"}, {"Section types", "/cms_slots"}, {"All sections", "/cms_content_areas"}, {"About", "/about"}])

    ~H"""
    <header class="border-b border-zinc-200 bg-white px-4 py-3 sm:px-6 lg:px-8">
      <div class="mx-auto flex max-w-6xl flex-wrap items-center gap-x-6 gap-y-3">
        <.link navigate={DeadSimpleCms.path("/cms_pages")} class="flex items-center gap-2 font-semibold text-zinc-900">
          <img src={~p"/images/logo.svg"} width="28" alt="" /> Content
        </.link>
        <nav aria-label="Content" class="flex flex-wrap items-center gap-1 text-sm">
          <.link :for={{label, path} <- @content_links} navigate={DeadSimpleCms.path(path)} class="rounded-md px-3 py-1.5 font-medium text-zinc-700 hover:bg-zinc-100">{label}</.link>
        </nav>
        <nav aria-label="Setup" class="flex flex-wrap items-center gap-1 text-sm sm:ml-auto">
          <span class="px-2 text-[0.65rem] font-bold uppercase tracking-[0.2em] text-zinc-400">Setup</span>
          <.link :for={{label, path} <- @setup_links} navigate={DeadSimpleCms.path(path)} class="rounded-md px-3 py-1.5 text-zinc-500 hover:bg-zinc-100 hover:text-zinc-800">{label}</.link>
        </nav>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-6xl space-y-4">
        {@inner_content}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
