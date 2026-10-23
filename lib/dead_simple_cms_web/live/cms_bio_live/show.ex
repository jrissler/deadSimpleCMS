defmodule DeadSimpleCmsWeb.CmsBioLive.Show do
  @moduledoc "A bio as a profile card: photo, name, job title, about, contact and social links."
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.SpecialContent

  @social [facebook: "Facebook", instagram: "Instagram", tik_tok: "TikTok", linked_in: "LinkedIn"]

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@cms_bio.name} sub_title="Bio" description={@cms_bio.job_title || "Profile"}>
      <:action>
        <.button navigate={DeadSimpleCms.path("/cms_bios")}>
          <.icon name="hero-arrow-left" class="size-4" /> All bios
        </.button>
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_bios/#{@cms_bio.id}/edit?return_to=show")}>
          <.icon name="hero-pencil" class="size-4" /> Edit bio
        </.button>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="mx-auto grid max-w-5xl gap-6 px-4 sm:px-6 lg:grid-cols-[minmax(0,1fr)_18rem] lg:px-8">
        <article id="bio-profile" class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm sm:p-8">
          <div class="flex flex-col gap-6 sm:flex-row sm:items-start">
            <img :if={@cms_bio.cms_image} src={@cms_bio.cms_image.url} alt={@cms_bio.cms_image.alt || @cms_bio.name} class="h-40 w-40 shrink-0 rounded-xl object-cover ring-1 ring-zinc-200" />
            <div :if={!@cms_bio.cms_image} class="grid h-40 w-40 shrink-0 place-items-center rounded-xl bg-zinc-100 text-zinc-400 ring-1 ring-zinc-200">
              <.icon name="hero-user" class="size-12" />
            </div>
            <div class="min-w-0 flex-1">
              <h2 class="text-2xl font-semibold tracking-tight text-zinc-900">{@cms_bio.name}</h2>
              <p :if={@cms_bio.job_title} class="mt-1 text-base font-medium text-zinc-600">{@cms_bio.job_title}</p>
              <p :if={@cms_bio.tag_line} class="mt-3 text-sm italic text-zinc-500">{@cms_bio.tag_line}</p>
            </div>
          </div>

          <div :if={@cms_bio.description} class="mt-6 whitespace-pre-line border-t border-zinc-100 pt-6 text-sm leading-6 text-zinc-700">{@cms_bio.description}</div>
          <p :if={!@cms_bio.description} class="mt-6 border-t border-zinc-100 pt-6 text-sm text-zinc-500">No "About them" text yet. Edit the bio to add some.</p>
        </article>

        <aside class="space-y-6">
          <div class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
            <h2 class="text-base font-semibold text-zinc-900">On the site</h2>
            <dl class="mt-4 space-y-3 text-sm">
              <div>
                <dt class="text-zinc-500">Status</dt>
                <dd class="mt-1">
                  <.status_badge tone={if @cms_bio.visible, do: :good, else: :muted}>{if @cms_bio.visible, do: "Shown", else: "Hidden"}</.status_badge>
                </dd>
              </div>
              <div>
                <dt class="text-zinc-500">Profile address</dt>
                <dd class="mt-1 break-all text-zinc-900">{@cms_bio.slug}</dd>
              </div>
              <div>
                <dt class="text-zinc-500">Last updated</dt>
                <dd class="mt-1 text-zinc-900">{friendly_date(@cms_bio.updated_at)}</dd>
              </div>
            </dl>
          </div>

          <div class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
            <h2 class="text-base font-semibold text-zinc-900">Contact and social</h2>
            <ul :if={@links != []} id="bio-links" class="mt-4 space-y-3 text-sm">
              <li :for={link <- @links} class="flex items-center gap-2">
                <.icon name={link.icon} class="size-4 shrink-0 text-zinc-400" />
                <a href={link.href} target={link.external && "_blank"} rel={link.external && "noopener noreferrer"} class="min-w-0 truncate font-medium text-indigo-600 hover:text-indigo-500">
                  {link.label}
                </a>
              </li>
            </ul>
            <p :if={@links == []} class="mt-4 text-sm text-zinc-500">No contact details or social links yet.</p>
          </div>
        </aside>
      </div>
    </main>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    cms_bio = SpecialContent.get_cms_bio!(id)

    {:ok, socket |> assign(:page_title, cms_bio.name) |> assign(:cms_bio, cms_bio) |> assign(:links, links(cms_bio))}
  end

  defp links(cms_bio) do
    contact = [
      present(cms_bio.email) && %{icon: "hero-envelope", label: cms_bio.email, href: "mailto:" <> cms_bio.email, external: false},
      present(cms_bio.phone_number) && %{icon: "hero-phone", label: cms_bio.phone_number, href: "tel:" <> String.replace(cms_bio.phone_number, ~r/[^\d+]/, ""), external: false}
    ]

    social =
      for {field, name} <- @social, present(Map.get(cms_bio, field)) do
        %{icon: "hero-arrow-top-right-on-square", label: name, href: web_href(Map.get(cms_bio, field)), external: true}
      end

    Enum.filter(contact, & &1) ++ social
  end

  defp web_href(url), do: if(url =~ ~r/^https?:\/\//i, do: url, else: "https://" <> url)

  defp present(value) when is_binary(value), do: String.trim(value) != "" && value
  defp present(_value), do: nil
end
