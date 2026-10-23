defmodule DeadSimpleCms.Cms do
  @moduledoc """
  The Cms context.
  """

  import Ecto.Query, warn: false

  alias DeadSimpleCms.Cms.CmsImage
  alias DeadSimpleCms.Cms.CmsContentArea
  alias DeadSimpleCms.Cms.CmsPage
  alias DeadSimpleCms.Cms.CmsPageTemplate
  alias DeadSimpleCms.Cms.CmsSlot
  alias DeadSimpleCms.Uploaders.S3Uploader

  defp repo, do: DeadSimpleCms.repo!()

  @doc """
  Returns the list of cms_pages.

  ## Examples

      iex> list_cms_pages()
      [%CmsPage{}, ...]

  """
  def list_cms_pages do
    repo().all(CmsPage)
  end

  @doc """
  Gets a single cms_page.

  Raises `Ecto.NoResultsError` if the Cms page does not exist.

  ## Examples

      iex> get_cms_page!(123)
      %CmsPage{}

      iex> get_cms_page!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cms_page!(id) do
    repo().get!(CmsPage, id) |> repo().preload([:og_image, cms_content_areas: from(a in CmsContentArea, order_by: [asc: a.position], preload: [:cms_image, :cms_slot])])
  end

  @doc """
  Returns a published CMS page by slug, preloading its visible content areas.

  This function is intended for public page rendering. It enforces the
  following guarantees:

  - Only pages with `published == true` are returned
  - Only content areas with `visible == true` are preloaded
  - Content areas are ordered by `position` ascending
  - The page template, when set, is preloaded with its visible *shared*
    content areas, so a host can render them as blocks on every page that
    uses the template
  - Returns `nil` if no published page exists for the given slug

  Layout, grouping, and presentation decisions remain the responsibility of the host application.
  """
  def get_published_page_by_slug(slug) do
    from(p in CmsPage, where: p.slug == ^slug and p.published == true, preload: ^public_page_preloads())
    |> repo().one()
  end

  @doc """
  Returns a CMS page by slug, published or not, with the same preloads as
  `get_published_page_by_slug/1`. For a host's full-page preview route (see
  `DeadSimpleCms.page_preview_url/1`), which must sit behind the host's own
  authentication. Returns `nil` if no page has the slug.
  """
  def get_preview_page_by_slug(slug) do
    from(p in CmsPage, where: p.slug == ^slug, preload: ^public_page_preloads())
    |> repo().one()
  end

  defp public_page_preloads do
    visible_areas_query = from(a in CmsContentArea, where: a.visible == true, order_by: [asc: a.position], preload: [:cms_image, :cms_slot])

    shared_areas_query = from(a in visible_areas_query, where: a.shared == true)

    [:og_image, cms_content_areas: visible_areas_query, cms_page_template: [cms_content_areas: shared_areas_query]]
  end

  @doc """
  Copies a page template's content areas into a page, as starter sections
  that are then edited independently of the template.

  Copies name, slot, position, title, subtitle, body, image and visibility.
  Skips the template's shared areas, which render on every page instead.
  Does nothing when the page has no template or already has content areas,
  so it is safe to call after every create. Returns the number of areas
  copied.
  """
  def copy_template_areas_to_page(%CmsPage{cms_page_template_id: nil}), do: {:ok, 0}

  def copy_template_areas_to_page(%CmsPage{id: page_id, cms_page_template_id: template_id}) do
    if repo().exists?(from(a in CmsContentArea, where: a.cms_page_id == ^page_id)) do
      {:ok, 0}
    else
      template_areas = repo().all(from(a in CmsContentArea, where: a.cms_page_template_id == ^template_id and a.shared == false, order_by: [asc: a.position]))

      repo().transaction(fn ->
        Enum.each(template_areas, fn area ->
          area
          |> Map.take([:name, :cms_slot_id, :position, :title, :subtitle, :body_md, :cms_image_id, :visible])
          |> Map.put(:cms_page_id, page_id)
          |> create_cms_content_area()
          |> case do
            {:ok, _} -> :ok
            {:error, changeset} -> repo().rollback(changeset)
          end
        end)

        length(template_areas)
      end)
    end
  end

  @doc """
  Returns published pages that should appear in a sitemap, ordered by slug.

  Pages marked `noindex` are excluded. The host app owns the sitemap route,
  URL structure, and XML rendering.

  ## Examples

      iex> list_sitemap_cms_pages()
      [%CmsPage{}, ...]

  """
  def list_sitemap_cms_pages do
    from(p in CmsPage, where: p.published == true and p.noindex == false, order_by: [asc: p.slug])
    |> repo().all()
  end

  @doc """
  Returns resolved SEO metadata for a page, for the host app to render into
  `<head>`.

  - `:title` falls back to the page `title` when `meta_title` is blank
  - `:description` and `:og_image_url` are `nil` when unset
  - `:robots` is `"noindex, follow"` when `noindex` is set, otherwise `"index, follow"`

  `:og_image_url` and `:og_image_alt` require `og_image` to be preloaded
  (`get_cms_page!/1` and `get_published_page_by_slug/1` do this).

  The canonical URL is not included: it depends on the host app's routes and
  domain, so the host builds it (usually a self-referencing URL for the page).

  ## Examples

      iex> page_seo(cms_page)
      %{title: "Yacht Charter Marketing", description: "...", og_image_url: nil, og_image_alt: nil, robots: "index, follow"}

  """
  def page_seo(%CmsPage{} = cms_page) do
    og_image = if match?(%CmsImage{}, cms_page.og_image), do: cms_page.og_image

    %{
      title: presence(cms_page.meta_title) || cms_page.title,
      description: presence(cms_page.meta_description),
      og_image_url: image_url(og_image),
      og_image_alt: og_image && presence(og_image.alt),
      robots: if(cms_page.noindex, do: "noindex, follow", else: "index, follow")
    }
  end

  @doc """
  Returns the URL to show an image at, or `nil` without an image.

  With `config :dead_simple_cms, image_urls: :signed`, it's a presigned S3 GET
  URL that expires after an hour, for private buckets. Otherwise (the default,
  `:public`) it's the stored `url`, which needs a public bucket or CDN. An image
  whose `url` isn't in the configured bucket is returned as stored.

  ## Examples

      iex> image_url(cms_image)
      "https://bucket.s3.amazonaws.com/uploads/cms_images/.../hero.jpg"

  """
  def image_url(nil), do: nil

  def image_url(%CmsImage{url: url}) do
    with :signed <- Application.get_env(:dead_simple_cms, :image_urls, :public),
         {:ok, signed_url} <- S3Uploader.generate_presigned_download_url(url) do
      signed_url
    else
      _ -> url
    end
  end

  defp presence(value) when is_binary(value), do: if(String.trim(value) == "", do: nil, else: value)
  defp presence(_value), do: nil

  @doc """
  Creates a cms_page.

  ## Examples

      iex> create_cms_page(%{field: value})
      {:ok, %CmsPage{}}

      iex> create_cms_page(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cms_page(attrs) do
    %CmsPage{}
    |> CmsPage.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Updates a cms_page.

  ## Examples

      iex> update_cms_page(cms_page, %{field: new_value})
      {:ok, %CmsPage{}}

      iex> update_cms_page(cms_page, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cms_page(%CmsPage{} = cms_page, attrs) do
    cms_page
    |> CmsPage.changeset(attrs)
    |> repo().update()
  end

  @doc """
  Deletes a cms_page.

  ## Examples

      iex> delete_cms_page(cms_page)
      {:ok, %CmsPage{}}

      iex> delete_cms_page(cms_page)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cms_page(%CmsPage{} = cms_page) do
    repo().delete(cms_page)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cms_page changes.

  ## Examples

      iex> change_cms_page(cms_page)
      %Ecto.Changeset{data: %CmsPage{}}

  """
  def change_cms_page(%CmsPage{} = cms_page, attrs \\ %{}) do
    CmsPage.changeset(cms_page, attrs)
  end

  @doc """
  Returns the list of cms_images.

  ## Examples

      iex> list_cms_images()
      [%CmsImage{}, ...]

  """
  def list_cms_images do
    repo().all(CmsImage)
  end

  @doc """
  Gets a single cms_image.

  Raises `Ecto.NoResultsError` if the Cms image does not exist.

  ## Examples

      iex> get_cms_image!(123)
      %CmsImage{}

      iex> get_cms_image!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cms_image!(id), do: repo().get!(CmsImage, id)

  @doc """
  Creates a cms_image.

  ## Examples

      iex> create_cms_image(%{field: value})
      {:ok, %CmsImage{}}

      iex> create_cms_image(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cms_image(attrs) do
    %CmsImage{}
    |> CmsImage.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Updates a cms_image.

  ## Examples

      iex> update_cms_image(cms_image, %{field: new_value})
      {:ok, %CmsImage{}}

      iex> update_cms_image(cms_image, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cms_image(%CmsImage{} = cms_image, attrs) do
    cms_image
    |> CmsImage.changeset(attrs)
    |> repo().update()
  end

  @doc """
  Deletes a cms_image.

  ## Examples

      iex> delete_cms_image(cms_image)
      {:ok, %CmsImage{}}

      iex> delete_cms_image(cms_image)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cms_image(%CmsImage{} = cms_image) do
    repo().delete(cms_image)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cms_image changes.

  ## Examples

      iex> change_cms_image(cms_image)
      %Ecto.Changeset{data: %CmsImage{}}

  """
  def change_cms_image(%CmsImage{} = cms_image, attrs \\ %{}) do
    CmsImage.changeset(cms_image, attrs)
  end

  @doc """
  Returns the list of cms_content_areas.

  ## Examples

      iex> list_cms_content_areas()
      [%CmsContentArea{}, ...]

  """
  def list_cms_content_areas do
    repo().all(CmsContentArea)
  end

  @doc """
  Gets a single cms_content_area.

  Raises `Ecto.NoResultsError` if the Cms content area does not exist.

  ## Examples

      iex> get_cms_content_area!(123)
      %CmsContentArea{}

      iex> get_cms_content_area!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cms_content_area!(id), do: repo().get!(CmsContentArea, id) |> repo().preload(:cms_image)

  @doc """
  Creates a cms_content_area.

  ## Examples

      iex> create_cms_content_area(%{field: value})
      {:ok, %CmsContentArea{}}

      iex> create_cms_content_area(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cms_content_area(attrs) do
    %CmsContentArea{}
    |> CmsContentArea.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Updates a cms_content_area.

  ## Examples

      iex> update_cms_content_area(cms_content_area, %{field: new_value})
      {:ok, %CmsContentArea{}}

      iex> update_cms_content_area(cms_content_area, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cms_content_area(%CmsContentArea{} = cms_content_area, attrs) do
    cms_content_area
    |> CmsContentArea.changeset(attrs)
    |> repo().update()
  end

  @doc """
  Deletes a cms_content_area.

  ## Examples

      iex> delete_cms_content_area(cms_content_area)
      {:ok, %CmsContentArea{}}

      iex> delete_cms_content_area(cms_content_area)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cms_content_area(%CmsContentArea{} = cms_content_area) do
    repo().delete(cms_content_area)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cms_content_area changes.

  ## Examples

      iex> change_cms_content_area(cms_content_area)
      %Ecto.Changeset{data: %CmsContentArea{}}

  """
  def change_cms_content_area(%CmsContentArea{} = cms_content_area, attrs \\ %{}) do
    CmsContentArea.changeset(cms_content_area, attrs)
  end

  @doc """
  The content areas of a page (`{:page, id}`) or template (`{:template, id}`),
  in order, with their image and slot.
  """
  def list_owner_content_areas(owner) do
    from(a in owner_areas_query(owner), order_by: [asc: a.position, asc: a.inserted_at], preload: [:cms_image, :cms_slot])
    |> repo().all()
  end

  @doc "The position for a new content area at the end of a page or template."
  def next_content_area_position(owner) do
    (repo().one(from(a in owner_areas_query(owner), select: max(a.position))) || -1) + 1
  end

  @doc """
  Moves a content area one place `:up` or `:down` among its page's (or
  template's) areas, renumbering them 0, 1, 2... Returns `:ok`, or `:noop`
  when it is already first or last.
  """
  def move_cms_content_area(%CmsContentArea{} = area, direction) when direction in [:up, :down] do
    owner = if area.cms_page_id, do: {:page, area.cms_page_id}, else: {:template, area.cms_page_template_id}
    ids = owner |> list_owner_content_areas() |> Enum.map(& &1.id)
    index = Enum.find_index(ids, &(&1 == area.id))
    target = if direction == :up, do: index - 1, else: index + 1

    if target < 0 or target >= length(ids) do
      :noop
    else
      reordered = ids |> List.replace_at(index, Enum.at(ids, target)) |> List.replace_at(target, area.id)

      repo().transaction(fn ->
        reordered |> Enum.with_index() |> Enum.each(fn {id, position} -> repo().update_all(from(a in CmsContentArea, where: a.id == ^id), set: [position: position]) end)
      end)

      :ok
    end
  end

  defp owner_areas_query({:page, id}), do: from(a in CmsContentArea, where: a.cms_page_id == ^id)
  defp owner_areas_query({:template, id}), do: from(a in CmsContentArea, where: a.cms_page_template_id == ^id)

  @doc """
  Where an image is used, so the admin can show it and warn before deleting:
  `%{areas: [...], bios: [...], pages: [...]}`. Areas come with their page or
  template; pages are those using it as their social share image.
  """
  def image_usage(%CmsImage{id: id}) do
    %{
      areas: repo().all(from(a in CmsContentArea, where: a.cms_image_id == ^id, order_by: a.name, preload: [:cms_page, :cms_page_template])),
      bios: repo().all(from(b in DeadSimpleCms.SpecialContent.CmsBio, where: b.cms_image_id == ^id, order_by: b.name)),
      pages: repo().all(from(p in CmsPage, where: p.og_image_id == ^id, order_by: p.title))
    }
  end

  @doc "How many content areas use each slot, as `%{slot_id => count}`."
  def slot_usage_counts do
    from(a in CmsContentArea, where: not is_nil(a.cms_slot_id), group_by: a.cms_slot_id, select: {a.cms_slot_id, count(a.id)})
    |> repo().all()
    |> Map.new()
  end

  @doc "How many content areas each page and template has, as `%{id => count}`."
  def content_area_counts do
    from(a in CmsContentArea, select: {coalesce(a.cms_page_id, a.cms_page_template_id), count(a.id)}, group_by: [a.cms_page_id, a.cms_page_template_id])
    |> repo().all()
    |> Map.new()
  end

  @doc """
  Returns the list of cms_slots.

  ## Examples

      iex> list_cms_slots()
      [%CmsSlot{}, ...]

  """
  def list_cms_slots do
    repo().all(CmsSlot)
  end

  @doc """
  Gets a single cms_slot.

  Raises `Ecto.NoResultsError` if the Cms slot does not exist.

  ## Examples

      iex> get_cms_slot!(123)
      %CmsSlot{}

      iex> get_cms_slot!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cms_slot!(id), do: repo().get!(CmsSlot, id)

  @doc """
  Creates a cms_slot.

  ## Examples

      iex> create_cms_slot(%{field: value})
      {:ok, %CmsSlot{}}

      iex> create_cms_slot(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cms_slot(attrs) do
    %CmsSlot{}
    |> CmsSlot.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Updates a cms_slot.

  ## Examples

      iex> update_cms_slot(cms_slot, %{field: new_value})
      {:ok, %CmsSlot{}}

      iex> update_cms_slot(cms_slot, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cms_slot(%CmsSlot{} = cms_slot, attrs) do
    cms_slot
    |> CmsSlot.changeset(attrs)
    |> repo().update()
  end

  @doc """
  Deletes a cms_slot.

  ## Examples

      iex> delete_cms_slot(cms_slot)
      {:ok, %CmsSlot{}}

      iex> delete_cms_slot(cms_slot)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cms_slot(%CmsSlot{} = cms_slot) do
    repo().delete(cms_slot)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cms_slot changes.

  ## Examples

      iex> change_cms_slot(cms_slot)
      %Ecto.Changeset{data: %CmsSlot{}}

  """
  def change_cms_slot(%CmsSlot{} = cms_slot, attrs \\ %{}) do
    CmsSlot.changeset(cms_slot, attrs)
  end

  @doc """
  Returns the list of cms_page_templates.

  ## Examples

      iex> list_cms_page_templates()
      [%CmsPageTemplate{}, ...]

  """
  def list_cms_page_templates do
    repo().all(CmsPageTemplate)
  end

  @doc """
  Gets a single cms_page_template.

  Raises `Ecto.NoResultsError` if the Cms page template does not exist.

  ## Examples

      iex> get_cms_page_template!(123)
      %CmsPageTemplate{}

      iex> get_cms_page_template!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cms_page_template!(id), do: repo().get!(CmsPageTemplate, id) |> repo().preload(cms_content_areas: from(a in CmsContentArea, order_by: [asc: a.position], preload: [:cms_image, :cms_slot]))

  @doc """
  Creates a cms_page_template.

  ## Examples

      iex> create_cms_page_template(%{field: value})
      {:ok, %CmsPageTemplate{}}

      iex> create_cms_page_template(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cms_page_template(attrs) do
    %CmsPageTemplate{}
    |> CmsPageTemplate.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Updates a cms_page_template.

  ## Examples

      iex> update_cms_page_template(cms_page_template, %{field: new_value})
      {:ok, %CmsPageTemplate{}}

      iex> update_cms_page_template(cms_page_template, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cms_page_template(%CmsPageTemplate{} = cms_page_template, attrs) do
    cms_page_template
    |> CmsPageTemplate.changeset(attrs)
    |> repo().update()
  end

  @doc """
  Deletes a cms_page_template.

  ## Examples

      iex> delete_cms_page_template(cms_page_template)
      {:ok, %CmsPageTemplate{}}

      iex> delete_cms_page_template(cms_page_template)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cms_page_template(%CmsPageTemplate{} = cms_page_template) do
    repo().delete(cms_page_template)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cms_page_template changes.

  ## Examples

      iex> change_cms_page_template(cms_page_template)
      %Ecto.Changeset{data: %CmsPageTemplate{}}

  """
  def change_cms_page_template(%CmsPageTemplate{} = cms_page_template, attrs \\ %{}) do
    CmsPageTemplate.changeset(cms_page_template, attrs)
  end
end
