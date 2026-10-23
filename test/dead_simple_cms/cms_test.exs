defmodule DeadSimpleCms.CmsTest do
  @moduledoc false

  use DeadSimpleCms.DataCase

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsContentArea
  alias DeadSimpleCms.Cms.CmsImage
  alias DeadSimpleCms.Cms.CmsPage
  alias DeadSimpleCms.Cms.CmsPageTemplate
  alias DeadSimpleCms.Cms.CmsSlot

  setup :base_data

  describe "cms_pages" do
    test "list_cms_pages/0 returns all cms_pages", %{data: data} do
      assert Cms.list_cms_pages() == [data.cms_page]
    end

    test "get_cms_page!/1 returns the cms_page with given id", %{data: data} do
      assert Cms.get_cms_page!(data.cms_page.id) == Repo.preload(data.cms_page, [:og_image, cms_content_areas: [:cms_image, :cms_slot]])
    end

    test "get_published_page_by_slug/1 returns the cms_page with given slug", %{data: data} do
      assert Cms.get_published_page_by_slug(data.cms_page.slug) == Repo.preload(data.cms_page, [:og_image, cms_content_areas: [:cms_image, :cms_slot], cms_page_template: [cms_content_areas: [:cms_image, :cms_slot]]])
    end

    test "get_published_page_by_slug/1 preloads the template's visible shared areas", %{data: data} do
      shared = insert(:cms_content_area, cms_page_template_id: data.cms_page_template.id, cms_slot_id: data.cms_slot.id, name: "follow_along", shared: true)
      insert(:cms_content_area, cms_page_template_id: data.cms_page_template.id, cms_slot_id: data.cms_slot.id, name: "hidden", shared: true, visible: false)
      insert(:cms_content_area, cms_page_template_id: data.cms_page_template.id, cms_slot_id: data.cms_slot.id, name: "starter")

      page = Cms.get_published_page_by_slug(data.cms_page.slug)

      assert Enum.map(page.cms_page_template.cms_content_areas, & &1.id) == [shared.id]
      assert Enum.map(page.cms_content_areas, & &1.id) == [data.cms_content_area.id]
    end

    test "get_preview_page_by_slug/1 includes unpublished pages", %{data: data} do
      draft = insert(:cms_page, published: false)

      assert Cms.get_published_page_by_slug(draft.slug) == nil
      assert %CmsPage{id: id, cms_content_areas: [], cms_page_template: nil} = Cms.get_preview_page_by_slug(draft.slug)
      assert id == draft.id
      assert Cms.get_preview_page_by_slug(data.cms_page.slug).id == data.cms_page.id
      assert Cms.get_preview_page_by_slug("no-such-page") == nil
    end

    test "copy_template_areas_to_page/1 gives a new page the template's sections", %{data: data} do
      insert(:cms_content_area, cms_page_template_id: data.cms_page_template.id, cms_slot_id: data.cms_slot.id, cms_image_id: data.cms_image.id, name: "hero", position: 0, title: "Hero")
      insert(:cms_content_area, cms_page_template_id: data.cms_page_template.id, cms_slot_id: data.cms_slot.id, name: "story", position: 1, title: "Story", visible: false)
      insert(:cms_content_area, cms_page_template_id: data.cms_page_template.id, cms_slot_id: data.cms_slot.id, name: "follow_along", position: 2, shared: true)
      page = insert(:cms_page, cms_page_template_id: data.cms_page_template.id)

      assert {:ok, 2} = Cms.copy_template_areas_to_page(page)

      areas = Cms.get_cms_page!(page.id).cms_content_areas
      assert Enum.map(areas, &{&1.name, &1.position, &1.title, &1.visible}) == [{"hero", 0, "Hero", true}, {"story", 1, "Story", false}]
      assert hd(areas).cms_image_id == data.cms_image.id
      assert Enum.all?(areas, &is_nil(&1.cms_page_template_id))

      # Shared areas aren't copied; the template keeps its own sections; a second call doesn't duplicate them.
      assert length(Cms.get_cms_page_template!(data.cms_page_template.id).cms_content_areas) == 3
      assert {:ok, 0} = Cms.copy_template_areas_to_page(page)
    end

    test "copy_template_areas_to_page/1 skips pages without a template or with sections already", %{data: data} do
      insert(:cms_content_area, cms_page_template_id: data.cms_page_template.id, cms_slot_id: data.cms_slot.id, name: "hero")

      assert {:ok, 0} = Cms.copy_template_areas_to_page(insert(:cms_page, cms_page_template_id: nil))
      assert {:ok, 0} = Cms.copy_template_areas_to_page(data.cms_page)
      assert [_] = Cms.get_cms_page!(data.cms_page.id).cms_content_areas
    end

    test "create_cms_page/1 with valid data creates a cms_page" do
      attrs = params_for(:cms_page, title: "some title")

      assert {:ok, %CmsPage{} = cms_page} = Cms.create_cms_page(attrs)
      assert cms_page.title == "some title"
      assert cms_page.slug == attrs.slug
      assert cms_page.published
      assert cms_page.published_at == attrs.published_at
    end

    test "create_cms_page/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{errors: errors}} = Cms.create_cms_page(params_for(:cms_page, title: ""))
      assert errors == [{:title, {"can't be blank", [validation: :required]}}]
    end

    test "update_cms_page/2 with valid data updates the cms_page", %{data: data} do
      assert {:ok, %CmsPage{} = cms_page} = Cms.update_cms_page(data.cms_page, %{title: "some updated title"})
      assert cms_page.title == "some updated title"
      assert cms_page.slug == data.cms_page.slug
      assert cms_page.published == data.cms_page.published
      assert cms_page.published_at == data.cms_page.published_at
    end

    test "update_cms_page/2 with invalid data returns error changeset", %{data: data} do
      assert {:error, %Ecto.Changeset{errors: errors}} = Cms.update_cms_page(data.cms_page, params_for(:cms_page, title: ""))
      assert errors == [{:title, {"can't be blank", [validation: :required]}}]
      assert Repo.preload(data.cms_page, [:og_image, cms_content_areas: [:cms_image, :cms_slot]]) == Cms.get_cms_page!(data.cms_page.id)
    end

    test "delete_cms_page/1 deletes the cms_page", %{data: data} do
      assert {:ok, %CmsPage{}} = Cms.delete_cms_page(data.cms_page)
      assert_raise Ecto.NoResultsError, fn -> Cms.get_cms_page!(data.cms_page.id) end
    end

    test "change_cms_page/1 returns a cms_page changeset", %{data: data} do
      assert %Ecto.Changeset{} = Cms.change_cms_page(data.cms_page)
    end

    test "create_cms_page/1 with SEO data creates a cms_page", %{data: data} do
      attrs = params_for(:cms_page, meta_title: "Yacht Charter Marketing", meta_description: "Marketing for charter operators.", noindex: true, og_image_id: data.cms_image.id)

      assert {:ok, %CmsPage{} = cms_page} = Cms.create_cms_page(attrs)
      assert cms_page.meta_title == "Yacht Charter Marketing"
      assert cms_page.meta_description == "Marketing for charter operators."
      assert cms_page.noindex
      assert cms_page.og_image_id == data.cms_image.id
    end

    test "create_cms_page/1 rejects a meta_description over 320 characters" do
      assert {:error, %Ecto.Changeset{errors: [meta_description: _]}} = Cms.create_cms_page(params_for(:cms_page, meta_description: String.duplicate("a", 321)))
    end

    test "list_sitemap_cms_pages/0 excludes unpublished and noindex pages", %{data: data} do
      insert(:cms_page, published: false)
      insert(:cms_page, noindex: true)

      assert Cms.list_sitemap_cms_pages() == [data.cms_page]
    end

    test "page_seo/1 falls back to the page title and defaults", %{data: data} do
      assert Cms.page_seo(data.cms_page) == %{title: data.cms_page.title, description: nil, og_image_url: nil, og_image_alt: nil, robots: "index, follow"}
    end

    test "page_seo/1 resolves SEO fields and the og image", %{data: data} do
      {:ok, cms_page} = Cms.update_cms_page(data.cms_page, %{meta_title: "Meta", meta_description: "Description", noindex: true, og_image_id: data.cms_image.id})
      cms_page = Cms.get_cms_page!(cms_page.id)

      assert Cms.page_seo(cms_page) == %{title: "Meta", description: "Description", og_image_url: data.cms_image.url, og_image_alt: data.cms_image.alt, robots: "noindex, follow"}
    end
  end

  describe "cms_images" do
    test "list_cms_images/0 returns all cms_images", %{data: data} do
      assert Cms.list_cms_images() == [data.cms_image]
    end

    test "get_cms_image!/1 returns the cms_image with given id", %{data: data} do
      assert Cms.get_cms_image!(data.cms_image.id) == data.cms_image
    end

    test "create_cms_image/1 with valid data creates a cms_image" do
      attrs = params_for(:cms_image, caption: "some caption")

      assert {:ok, %CmsImage{} = cms_image} = Cms.create_cms_image(attrs)
      assert cms_image.caption == "some caption"
      assert cms_image.filename == attrs.filename
      assert cms_image.width == attrs.width
      assert cms_image.url == attrs.url
      assert cms_image.alt == attrs.alt
      assert cms_image.height == attrs.height
      assert cms_image.content_type == attrs.content_type
    end

    test "create_cms_image/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{errors: errors}} = Cms.create_cms_image(params_for(:cms_image, filename: ""))
      assert errors == [{:filename, {"can't be blank", [validation: :required]}}]
    end

    test "update_cms_image/2 with valid data updates the cms_image", %{data: data} do
      attrs = params_for(:cms_image, filename: "some updated filename")

      assert {:ok, %CmsImage{} = cms_image} = Cms.update_cms_image(data.cms_image, attrs)
      assert cms_image.filename == "some updated filename"
      assert cms_image.width == attrs.width
      assert cms_image.url == attrs.url
      assert cms_image.alt == attrs.alt
      assert cms_image.caption == attrs.caption
      assert cms_image.height == attrs.height
      assert cms_image.content_type == attrs.content_type
    end

    test "update_cms_image/2 with invalid data returns error changeset", %{data: data} do
      assert {:error, %Ecto.Changeset{errors: errors}} = Cms.update_cms_image(data.cms_image, params_for(:cms_image, filename: ""))
      assert errors == [{:filename, {"can't be blank", [validation: :required]}}]
      assert data.cms_image == Cms.get_cms_image!(data.cms_image.id)
    end

    test "delete_cms_image/1 deletes the cms_image", %{data: data} do
      assert {:ok, %CmsImage{}} = Cms.delete_cms_image(data.cms_image)
      assert_raise Ecto.NoResultsError, fn -> Cms.get_cms_image!(data.cms_image.id) end
    end

    test "change_cms_image/1 returns a cms_image changeset", %{data: data} do
      assert %Ecto.Changeset{} = Cms.change_cms_image(data.cms_image)
    end
  end

  describe "cms_content_areas" do
    test "list_cms_content_areas/0 returns all cms_content_areas", %{data: data} do
      assert Cms.list_cms_content_areas() == [data.cms_content_area]
    end

    test "get_cms_content_area!/1 returns the cms_content_area with given id", %{data: data} do
      assert Cms.get_cms_content_area!(data.cms_content_area.id) == Repo.preload(data.cms_content_area, :cms_image)
    end

    test "create_cms_content_area/1 with valid data creates a cms_content_area", %{data: data} do
      attrs = params_for(:cms_content_area, name: "some name", cms_page_id: data.cms_page.id, cms_image_id: data.cms_image.id, cms_slot_id: data.cms_slot.id)

      assert {:ok, %CmsContentArea{} = cms_content_area} = Cms.create_cms_content_area(attrs)

      assert cms_content_area.name == "some name"
      assert cms_content_area.position == attrs.position
      assert cms_content_area.visible == attrs.visible
      assert cms_content_area.title == attrs.title
      assert cms_content_area.subtitle == attrs.subtitle
      assert cms_content_area.body_md == attrs.body_md
    end

    test "create_cms_content_area/1 with invalid data returns error changeset", %{data: data} do
      assert {:error, %Ecto.Changeset{errors: errors}} = Cms.create_cms_content_area(params_for(:cms_content_area, name: "", cms_page_id: data.cms_page.id, cms_image_id: data.cms_image.id, cms_slot_id: data.cms_slot.id))
      assert errors == [{:name, {"can't be blank", [validation: :required]}}]
    end

    test "update_cms_content_area/2 with valid data updates the cms_content_area", %{data: data} do
      attrs = params_for(:cms_content_area, name: "some updated name", cms_page_id: data.cms_page.id, cms_image_id: data.cms_image.id)

      assert {:ok, %CmsContentArea{} = cms_content_area} = Cms.update_cms_content_area(data.cms_content_area, attrs)

      assert cms_content_area.name == "some updated name"
      assert cms_content_area.position == attrs.position
      assert cms_content_area.visible == attrs.visible
      assert cms_content_area.title == attrs.title
      assert cms_content_area.subtitle == attrs.subtitle
      assert cms_content_area.body_md == attrs.body_md
      assert cms_content_area.cms_page_id == data.cms_page.id
      assert cms_content_area.cms_image_id == data.cms_image.id
    end

    test "update_cms_content_area/2 with invalid data returns error changeset", %{data: data} do
      assert {:error, %Ecto.Changeset{errors: errors}} = Cms.update_cms_content_area(data.cms_content_area, %{name: ""})
      assert errors == [{:name, {"can't be blank", [validation: :required]}}]
      assert Repo.preload(data.cms_content_area, :cms_image) == Cms.get_cms_content_area!(data.cms_content_area.id)
    end

    test "delete_cms_content_area/1 deletes the cms_content_area", %{data: data} do
      assert {:ok, %CmsContentArea{}} = Cms.delete_cms_content_area(data.cms_content_area)
      assert_raise Ecto.NoResultsError, fn -> Cms.get_cms_content_area!(data.cms_content_area.id) end
    end

    test "change_cms_content_area/1 returns a cms_content_area changeset", %{data: data} do
      assert %Ecto.Changeset{} = Cms.change_cms_content_area(data.cms_content_area)
    end
  end

  describe "cms_slots" do
    test "list_cms_slots/0 returns all cms_slots", %{data: data} do
      slots = Cms.list_cms_slots()

      assert Enum.any?(slots, &(&1.key == "standard_content"))
      assert Enum.any?(slots, &(&1.id == data.cms_slot.id))
    end

    test "get_cms_slot!/1 returns the cms_slot with given id", %{data: data} do
      assert Cms.get_cms_slot!(data.cms_slot.id) == data.cms_slot
    end

    test "create_cms_slot/1 with valid data creates a cms_slot" do
      attrs = params_for(:cms_slot, key: "hero_intro", name: "Hero Intro", description: "Primary hero content area")

      assert {:ok, %CmsSlot{} = cms_slot} = Cms.create_cms_slot(attrs)
      assert cms_slot.key == "hero_intro"
      assert cms_slot.name == "Hero Intro"
      assert cms_slot.description == "Primary hero content area"
    end

    test "create_cms_slot/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{errors: errors}} = Cms.create_cms_slot(params_for(:cms_slot, key: "", name: ""))
      assert errors == [key: {"can't be blank", [validation: :required]}, name: {"can't be blank", [validation: :required]}]
    end

    test "create_cms_slot/1 with non-unique key returns error changeset", %{data: data} do
      assert {:error, %Ecto.Changeset{errors: errors}} = Cms.create_cms_slot(params_for(:cms_slot, key: data.cms_slot.key))
      assert errors == [key: {"has already been taken", [{:constraint, :unique}, {:constraint_name, "cms_slots_key_index"}]}]
    end

    test "update_cms_slot/2 with valid data updates the cms_slot", %{data: data} do
      attrs = params_for(:cms_slot, key: "primary_cta", name: "Primary CTA", description: "Updated description")

      assert {:ok, %CmsSlot{} = cms_slot} = Cms.update_cms_slot(data.cms_slot, attrs)
      assert cms_slot.key == "primary_cta"
      assert cms_slot.name == "Primary CTA"
      assert cms_slot.description == "Updated description"
    end

    test "update_cms_slot/2 with invalid data returns error changeset", %{data: data} do
      assert {:error, %Ecto.Changeset{errors: errors}} = Cms.update_cms_slot(data.cms_slot, %{key: "", name: ""})
      assert errors == [key: {"can't be blank", [validation: :required]}, name: {"can't be blank", [validation: :required]}]
      assert data.cms_slot == Cms.get_cms_slot!(data.cms_slot.id)
    end

    test "delete_cms_slot/1 deletes the cms_slot", %{data: data} do
      assert {:ok, %CmsSlot{}} = Cms.delete_cms_slot(data.cms_slot)
      assert_raise Ecto.NoResultsError, fn -> Cms.get_cms_slot!(data.cms_slot.id) end
    end

    test "change_cms_slot/1 returns a cms_slot changeset", %{data: data} do
      assert %Ecto.Changeset{} = Cms.change_cms_slot(data.cms_slot)
    end
  end

  describe "cms_page_templates" do
    test "list_cms_page_templates/0 returns all cms_page_templates", %{data: data} do
      assert Cms.list_cms_page_templates() == [data.cms_page_template]
    end

    test "get_cms_page_template!/1 returns the cms_page_template with given id", %{data: data} do
      assert Cms.get_cms_page_template!(data.cms_page_template.id) == Repo.preload(data.cms_page_template, cms_content_areas: [:cms_image, :cms_slot])
    end

    test "create_cms_page_template/1 with valid data creates a cms_page_template" do
      attrs = %{key: "landing_page", name: "Landing Page", description: "Template for landing_page"}

      assert {:ok, %CmsPageTemplate{} = cms_page_template} = Cms.create_cms_page_template(attrs)
      assert cms_page_template.key == "landing_page"
      assert cms_page_template.name == "Landing Page"
      assert cms_page_template.description == "Template for landing_page"
    end

    test "create_cms_page_template/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{errors: errors}} = Cms.create_cms_page_template(%{key: "", name: ""})
      assert errors == [key: {"can't be blank", [validation: :required]}, name: {"can't be blank", [validation: :required]}]
    end

    test "create_cms_page_template/1 with non-unique key returns error changeset", %{data: data} do
      assert {:error, %Ecto.Changeset{errors: errors}} = Cms.create_cms_page_template(%{key: data.cms_page_template.key, name: "Another Home Page"})
      assert errors == [key: {"has already been taken", [{:constraint, :unique}, {:constraint_name, "cms_page_templates_key_index"}]}]
    end

    test "update_cms_page_template/2 with valid data updates the cms_page_template", %{data: data} do
      attrs = %{key: "landing_page", name: "Landing Page", description: "Updated description"}

      assert {:ok, %CmsPageTemplate{} = cms_page_template} = Cms.update_cms_page_template(data.cms_page_template, attrs)
      assert cms_page_template.key == "landing_page"
      assert cms_page_template.name == "Landing Page"
      assert cms_page_template.description == "Updated description"
    end

    test "update_cms_page_template/2 with invalid data returns error changeset", %{data: data} do
      assert {:error, %Ecto.Changeset{errors: errors}} = Cms.update_cms_page_template(data.cms_page_template, %{key: "", name: ""})
      assert errors == [key: {"can't be blank", [validation: :required]}, name: {"can't be blank", [validation: :required]}]
      assert Repo.preload(data.cms_page_template, cms_content_areas: [:cms_image, :cms_slot]) == Cms.get_cms_page_template!(data.cms_page_template.id)
    end

    test "delete_cms_page_template/1 deletes the cms_page_template", %{data: data} do
      assert {:ok, %CmsPageTemplate{}} = Cms.delete_cms_page_template(data.cms_page_template)
      assert_raise Ecto.NoResultsError, fn -> Cms.get_cms_page_template!(data.cms_page_template.id) end
    end

    test "change_cms_page_template/1 returns a cms_page_template changeset", %{data: data} do
      assert %Ecto.Changeset{} = Cms.change_cms_page_template(data.cms_page_template)
    end
  end
end
