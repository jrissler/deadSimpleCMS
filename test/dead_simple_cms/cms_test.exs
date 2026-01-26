defmodule DeadSimpleCms.CmsTest do
  @moduledoc false

  use DeadSimpleCms.DataCase

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsContentArea
  alias DeadSimpleCms.Cms.CmsImage
  alias DeadSimpleCms.Cms.CmsPage

  setup :base_data

  describe "cms_pages" do
    test "list_cms_pages/0 returns all cms_pages", %{data: data} do
      assert Cms.list_cms_pages() == [data.cms_page]
    end

    test "get_cms_page!/1 returns the cms_page with given id", %{data: data} do
      assert Cms.get_cms_page!(data.cms_page.id) == Repo.preload(data.cms_page, :cms_content_areas)
    end

    test "get_published_page_by_slug/1 returns the cms_page with given slug", %{data: data} do
      assert Cms.get_published_page_by_slug(data.cms_page.slug) == Repo.preload(data.cms_page, :cms_content_areas)
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
      assert Repo.preload(data.cms_page, :cms_content_areas) == Cms.get_cms_page!(data.cms_page.id)
    end

    test "delete_cms_page/1 deletes the cms_page", %{data: data} do
      assert {:ok, %CmsPage{}} = Cms.delete_cms_page(data.cms_page)
      assert_raise Ecto.NoResultsError, fn -> Cms.get_cms_page!(data.cms_page.id) end
    end

    test "change_cms_page/1 returns a cms_page changeset", %{data: data} do
      assert %Ecto.Changeset{} = Cms.change_cms_page(data.cms_page)
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
      assert Cms.get_cms_content_area!(data.cms_content_area.id) == data.cms_content_area
    end

    test "create_cms_content_area/1 with valid data creates a cms_content_area", %{data: data} do
      attrs = params_for(:cms_content_area, name: "some name", cms_page_id: data.cms_page.id, cms_image_id: data.cms_image.id)

      assert {:ok, %CmsContentArea{} = cms_content_area} = Cms.create_cms_content_area(attrs)

      assert cms_content_area.name == "some name"
      assert cms_content_area.position == attrs.position
      assert cms_content_area.visible == attrs.visible
      assert cms_content_area.title == attrs.title
      assert cms_content_area.subtitle == attrs.subtitle
      assert cms_content_area.body_md == attrs.body_md
    end

    test "create_cms_content_area/1 with invalid data returns error changeset", %{data: data} do
      assert {:error, %Ecto.Changeset{errors: errors}} = Cms.create_cms_content_area(params_for(:cms_content_area, name: "", cms_page_id: data.cms_page.id, cms_image_id: data.cms_image.id))
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
      assert data.cms_content_area == Cms.get_cms_content_area!(data.cms_content_area.id)
    end

    test "delete_cms_content_area/1 deletes the cms_content_area", %{data: data} do
      assert {:ok, %CmsContentArea{}} = Cms.delete_cms_content_area(data.cms_content_area)
      assert_raise Ecto.NoResultsError, fn -> Cms.get_cms_content_area!(data.cms_content_area.id) end
    end

    test "change_cms_content_area/1 returns a cms_content_area changeset", %{data: data} do
      assert %Ecto.Changeset{} = Cms.change_cms_content_area(data.cms_content_area)
    end
  end
end
