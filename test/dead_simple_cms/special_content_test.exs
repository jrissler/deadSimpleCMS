defmodule DeadSimpleCms.SpecialContentTest do
  @moduledoc false

  use DeadSimpleCms.DataCase

  alias DeadSimpleCms.SpecialContent
  alias DeadSimpleCms.SpecialContent.CmsBio

  setup :base_data

  describe "cms_bios" do
    test "list_cms_bios/0 returns all cms_bios", %{data: data} do
      assert SpecialContent.list_cms_bios() == [Repo.preload(data.cms_bio, :cms_image)]
    end

    test "get_cms_bio!/1 returns the cms_bio with given id", %{data: data} do
      assert SpecialContent.get_cms_bio!(data.cms_bio.id) == Repo.preload(data.cms_bio, :cms_image)
    end

    test "create_cms_bio/1 with valid data creates a cms_bio", %{data: data} do
      attrs = params_for(:cms_bio, name: "some name", cms_image_id: data.cms_image.id)

      assert {:ok, %CmsBio{} = cms_bio} = SpecialContent.create_cms_bio(attrs)
      assert cms_bio.name == "some name"
      assert cms_bio.job_title == attrs.job_title
      assert cms_bio.tag_line == attrs.tag_line
      assert cms_bio.description == attrs.description
      assert cms_bio.phone_number == attrs.phone_number
      assert cms_bio.email == attrs.email
      assert cms_bio.facebook == attrs.facebook
      assert cms_bio.instagram == attrs.instagram
      assert cms_bio.tik_tok == attrs.tik_tok
      assert cms_bio.linked_in == attrs.linked_in
      assert cms_bio.slug == attrs.slug
      assert cms_bio.visible == attrs.visible
      assert cms_bio.cms_image_id == data.cms_image.id
    end

    test "create_cms_bio/1 with invalid data returns error changeset", %{data: data} do
      assert {:error, %Ecto.Changeset{errors: errors}} = SpecialContent.create_cms_bio(params_for(:cms_bio, name: "", cms_image_id: data.cms_image.id))
      assert errors == [name: {"can't be blank", [validation: :required]}]
    end

    test "update_cms_bio/2 with valid data updates the cms_bio", %{data: data} do
      attrs = params_for(:cms_bio, name: "some updated name", slug: "some-updated-slug", cms_image_id: data.cms_image.id, visible: false)

      assert {:ok, %CmsBio{} = cms_bio} = SpecialContent.update_cms_bio(data.cms_bio, attrs)
      assert cms_bio.name == "some updated name"
      assert cms_bio.job_title == attrs.job_title
      assert cms_bio.tag_line == attrs.tag_line
      assert cms_bio.description == attrs.description
      assert cms_bio.phone_number == attrs.phone_number
      assert cms_bio.email == attrs.email
      assert cms_bio.facebook == attrs.facebook
      assert cms_bio.instagram == attrs.instagram
      assert cms_bio.tik_tok == attrs.tik_tok
      assert cms_bio.linked_in == attrs.linked_in
      assert cms_bio.slug == "some-updated-slug"
      assert cms_bio.visible == false
      assert cms_bio.cms_image_id == data.cms_image.id
    end

    test "update_cms_bio/2 with invalid data returns error changeset", %{data: data} do
      assert {:error, %Ecto.Changeset{errors: errors}} = SpecialContent.update_cms_bio(data.cms_bio, %{name: ""})
      assert errors == [name: {"can't be blank", [validation: :required]}]
      assert Repo.preload(data.cms_bio, :cms_image) == SpecialContent.get_cms_bio!(data.cms_bio.id)
    end

    test "delete_cms_bio/1 deletes the cms_bio", %{data: data} do
      assert {:ok, %CmsBio{}} = SpecialContent.delete_cms_bio(data.cms_bio)
      assert_raise Ecto.NoResultsError, fn -> SpecialContent.get_cms_bio!(data.cms_bio.id) end
    end

    test "change_cms_bio/1 returns a cms_bio changeset", %{data: data} do
      assert %Ecto.Changeset{} = SpecialContent.change_cms_bio(data.cms_bio)
    end
  end
end
