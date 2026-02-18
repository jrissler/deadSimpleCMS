defmodule DeadSimpleCmsWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: DeadSimpleCmsWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  attr :type, :string, default: "button"
  attr :variant, :string, default: "default"
  attr :navigate, :any, default: nil
  attr :patch, :any, default: nil
  attr :href, :string, default: nil
  attr :class, :string, default: ""
  attr :rest, :global, include: ~w(disabled form name value phx-click phx-disable-with)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <%= if @navigate || @patch || @href do %>
      <.link navigate={@navigate} patch={@patch} href={@href} class={button_class(@variant, @class)} {@rest}>{render_slot(@inner_block)}</.link>
    <% else %>
      <button type={@type} class={button_class(@variant, @class)} {@rest}>{render_slot(@inner_block)}</button>
    <% end %>
    """
  end

  defp button_class(variant, extra_class) do
    base = "inline-flex items-center justify-center gap-2 rounded-md px-3 py-2 text-sm font-semibold shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 disabled:opacity-50 disabled:pointer-events-none"

    variant_class =
      case variant do
        "primary" -> "bg-indigo-600 text-white hover:bg-indigo-500 focus-visible:outline-indigo-600"
        "danger" -> "bg-red-600 text-white hover:bg-red-500 focus-visible:outline-red-600"
        "default" -> "bg-white text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus-visible:outline-indigo-600"
        _ -> "bg-white text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus-visible:outline-indigo-600"
      end

    Enum.join(Enum.reject([base, variant_class, extra_class], &(&1 in [nil, ""])), " ")
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class || "w-full select", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class || "w-full textarea",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class || "w-full input",
            @errors != [] && (@error_class || "input-error")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">Actions</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc ~S"""
  Renders a styled “hero” content header card.

  This component provides a high-contrast, dark gradient header with subtle glow accents, a leading icon tile, and optional right-aligned actions. An optional tab strip can be rendered along the bottom for summary metrics or quick context.

  ## Assigns

    * `:main_title` - Primary heading text (required).
    * `:sub_title` - Secondary heading text shown above the main title (required).
    * `:description` - Short description line shown under the title (required).
    * `:sub_description` - Optional second description line shown under `:description`.
    * `:icon_class` - Icon CSS class for the leading icon (FontAwesome / Heroicons class string). Defaults to `"hero-chart-bar-square"`.

  ## Slots

    * `:action` - Optional slot rendered in the top-right for CTAs (links/buttons).
    * `:tab` - Optional slot(s) rendered as a bottom strip of summary items. Each tab supports:

      * `:value` - The primary value (number/text).
      * `:label` - The descriptor label.

  ## Examples

      <.content_header
        main_title="Listing Inquiries"
        sub_title="Sophisticated Yachting"
        description="Inquiries are records where a potential customer has filled out the contact-us form."
        sub_description="Review, follow up, and track conversions."
        icon_class="fa-light fa-ship"
      >
        <:action>
          <.link
            patch={~p"/posts/new"}
            class="flex items-center justify-center rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white hover:bg-green-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          >
            <.icon name="hero-plus" class="-ml-0.5 mr-1 h-5 w-5" />
            Add Post
          </.link>
        </:action>

        <:tab value="2" label="Active" />
        <:tab value="3" label="Drafts" />
        <:tab value="4" label="Scheduled" />
      </.content_header>
  """
  attr :main_title, :string, required: true
  attr :sub_title, :string, required: false, default: nil
  attr :description, :string, required: true
  attr :sub_description, :string, required: false, default: nil
  attr :icon_class, :string, required: false, default: "hero-chart-bar-square"

  slot :tab, required: false, doc: "the slot for showing tabs at bottom of header content" do
    attr :label, :any
    attr :value, :any
  end

  slot :action, doc: "the slot for showing a user action in the top right of card"

  def content_header(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <section aria-labelledby="overview-title" class="mt-2">
      <div class="relative overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        <h2 class="sr-only" id="overview-title">
          {@main_title}
          <span :if={@sub_title && @sub_title != ""}>{@sub_title}</span>
        </h2>

        <div class="absolute inset-0 bg-gradient-to-r from-slate-950 via-slate-900 to-slate-950 opacity-[0.96]"></div>
        <div class="absolute -top-24 -right-24 h-80 w-80 rounded-full bg-cyan-500/20 blur-3xl"></div>
        <div class="absolute -bottom-24 -left-24 h-80 w-80 rounded-full bg-blue-500/20 blur-3xl"></div>

        <div class="relative p-6 sm:p-7">
          <div class="sm:flex sm:items-center sm:justify-between">
            <div class="sm:flex sm:space-x-5 pr-2">
              <div class="flex-shrink-0">
                <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-white/10 ring-1 ring-white/15">
                  <i class={[@icon_class, "text-cyan-200"]}></i>
                </div>
              </div>

              <div class="mt-4 text-center sm:mt-0 sm:pt-0 sm:text-left">
                <p :if={@sub_title} class="text-sm font-medium text-white/70">{@sub_title}</p>
                <p class="text-xl font-semibold text-white sm:text-2xl">{@main_title}</p>
                <p class="mt-1 text-sm font-medium text-white/70">{@description}</p>
                <p :if={@sub_description} class="mt-1 text-sm font-medium text-white/70">{@sub_description}</p>
              </div>
            </div>

            <div class="mt-5 flex justify-center sm:mt-0 min-w-max">
              <%= for action <- @action do %>
                {render_slot(action)}
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- tabs -->
        <div class="relative grid grid-cols-1 divide-y divide-white/10 border-t border-white/10 bg-white/[0.04] sm:grid-cols-3 sm:divide-x sm:divide-y-0">
          <div :for={tab <- @tab} class="px-6 py-5 text-center text-sm font-medium">
            <span class="text-white">{tab[:value]}</span>
            <span class="ml-2 text-white/70">{tab[:label]}</span>
          </div>
        </div>
      </div>
    </section>
    """
  end

  @doc ~S"""
  Renders an admin table with generic styling and optional tab navigation.

  ## Examples

      <.admin_table id="users" rows={@users}>
        <:tab label="Active" patch="/boats?filters[sales_status]=active" class="your-class" />
        <:tab label="Archived" patch="/boats?filters[sales_status]=archived" class="your-class" />
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.admin_table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :extra_th_class, :string
    attr :extra_td_class, :string
  end

  slot :tab do
    attr :label, :string
    attr :patch, :string
    attr :class, :any
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def admin_table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="px-4 sm:px-0 border-b-1">
      <div class="sm:hidden mb-2">
        <label for="question-tabs" class="sr-only">Select a tab</label>
        <select id="question-tabs" class="block w-full border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-rose-500">
          <option selected="">Tab 1</option>
          <option>Tab 2</option>
          <option>Tab 3</option>
        </select>
      </div>
      <div class="hidden sm:block">
        <nav class="isolate flex divide-x divide-gray-200 shadow" aria-label="Tabs">
          <.link :for={tab <- @tab} patch={tab[:patch]} class={["group relative min-w-0 flex-1 overflow-hidden bg-white py-4 px-6 text-center text-sm font-medium hover:bg-gray-50 focus:z-10", tab[:class]]}>
            <span>{tab[:label]}</span>
            <span aria-hidden="true" class="absolute inset-x-0 bottom-0 h-0.5"></span>
          </.link>
        </nav>
      </div>
    </div>
    <div class="bg-white">
      <div class="mx-auto max-w-7xl">
        <div class="px-2 sm:px-6 lg:px-4">
          <div class="-mx-4 sm:-mx-0 pt-4">
            <table class="min-w-full divide-y divide-gray-300">
              <thead>
                <tr>
                  <th :for={col <- @col} class={["py-4 pl-2 pr-3 text-left text-sm font-semibold text-gray-900", col[:extra_th_class]]}>{col[:label]}</th>
                  <th :if={@action != []} class="relative p-0 pb-4">
                    <span class="sr-only">Actions</span>
                  </th>
                </tr>
              </thead>

              <tbody id={@id} phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"} class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700">
                <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
                  <td :for={{col, i} <- Enum.with_index(@col)} phx-click={@row_click && @row_click.(row)} class={["relative whitespace-nowrap px-3 py-1 text-sm text-gray-500", col[:extra_td_class], @row_click && "hover:cursor-pointer"]}>
                    <div class="block py-4 pr-6">
                      <span class="absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl" />
                      <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                        {render_slot(col, @row_item.(row))}
                      </span>
                    </div>
                  </td>
                  <td :if={@action != []} class="relative w-14 p-0">
                    <div class="relative whitespace-nowrap py-1 text-right text-sm font-medium pr-4">
                      <span :for={action <- @action} class="relative font-medium leading-6 text-indigo-600 hover:text-indigo-900">
                        {render_slot(action, @row_item.(row))}
                      </span>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def non_list_table(assigns) do
    ~H"""
    <table class="data-table w-full">
      <thead class="bg-gray-50">
        <tr>
          <%= for header <- @headers do %>
            <th class="data-table-th text-left" scope="col">
              {header}
            </th>
          <% end %>
        </tr>
      </thead>

      <tbody id={@object_name} class="bg-white divide-y divide-gray-200">
        <%= for row <- @row do %>
          <tr class="alternating">
            {render_slot(row)}
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition: {"transition-all ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95", "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition: {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(DeadSimpleCmsWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(DeadSimpleCmsWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
