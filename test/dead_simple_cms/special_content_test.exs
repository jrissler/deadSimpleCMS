defmodule DeadSimpleCms.SpecialContentTest do
  @moduledoc false

  use DeadSimpleCms.DataCase

  alias DeadSimpleCms.SpecialContent
  alias DeadSimpleCms.SpecialContent.CmsBio
  alias DeadSimpleCms.SpecialContent.CmsTestimonial

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

  describe "cms_testimonials" do
    test "list_cms_testimonials/0 returns all cms_testimonials", %{data: data} do
      assert SpecialContent.list_cms_testimonials() == [data.cms_testimonial]
    end

    test "get_cms_testimonial!/1 returns the cms_testimonial with given id", %{data: data} do
      assert SpecialContent.get_cms_testimonial!(data.cms_testimonial.id) == data.cms_testimonial
    end

    test "create_cms_testimonial/1 with valid data creates a cms_testimonial" do
      attrs = params_for(:cms_testimonial, name: "some name", quote: "some quote", stars: 5, visible: true)

      assert {:ok, %CmsTestimonial{} = cms_testimonial} = SpecialContent.create_cms_testimonial(attrs)
      assert cms_testimonial.name == "some name"
      assert cms_testimonial.title == attrs.title
      assert cms_testimonial.company == attrs.company
      assert cms_testimonial.source == attrs.source
      assert cms_testimonial.quote == "some quote"
      assert cms_testimonial.stars == 5
      assert cms_testimonial.visible == true
    end

    test "create_cms_testimonial/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{errors: errors}} = SpecialContent.create_cms_testimonial(%{name: "", quote: "", stars: nil, visible: nil})
      assert errors == [{:name, {"can't be blank", [validation: :required]}}, {:quote, {"can't be blank", [validation: :required]}}, {:stars, {"can't be blank", [validation: :required]}}, {:visible, {"can't be blank", [validation: :required]}}]
    end

    test "create_cms_testimonial/1 with invalid stars returns error changeset" do
      assert {:error, %Ecto.Changeset{errors: errors}} = SpecialContent.create_cms_testimonial(params_for(:cms_testimonial, stars: 42))
      assert errors == [stars: {"must be less than or equal to %{number}", [validation: :number, kind: :less_than_or_equal_to, number: 5]}]
    end

    test "update_cms_testimonial/2 with valid data updates the cms_testimonial", %{data: data} do
      attrs = params_for(:cms_testimonial, name: "some updated name", quote: "some updated quote", stars: 4, visible: false)

      assert {:ok, %CmsTestimonial{} = cms_testimonial} = SpecialContent.update_cms_testimonial(data.cms_testimonial, attrs)
      assert cms_testimonial.name == "some updated name"
      assert cms_testimonial.title == attrs.title
      assert cms_testimonial.company == attrs.company
      assert cms_testimonial.source == attrs.source
      assert cms_testimonial.quote == "some updated quote"
      assert cms_testimonial.stars == 4
      assert cms_testimonial.visible == false
    end

    test "update_cms_testimonial/2 with invalid data returns error changeset", %{data: data} do
      assert {:error, %Ecto.Changeset{errors: errors}} = SpecialContent.update_cms_testimonial(data.cms_testimonial, %{name: "", quote: "", stars: nil, visible: nil})
      assert errors == [{:name, {"can't be blank", [validation: :required]}}, {:quote, {"can't be blank", [validation: :required]}}, {:stars, {"can't be blank", [validation: :required]}}, {:visible, {"can't be blank", [validation: :required]}}]
      assert data.cms_testimonial == SpecialContent.get_cms_testimonial!(data.cms_testimonial.id)
    end

    test "update_cms_testimonial/2 with invalid stars returns error changeset", %{data: data} do
      assert {:error, %Ecto.Changeset{errors: errors}} = SpecialContent.update_cms_testimonial(data.cms_testimonial, %{stars: 0})
      assert errors == [stars: {"must be greater than or equal to %{number}", [validation: :number, kind: :greater_than_or_equal_to, number: 1]}]
      assert data.cms_testimonial == SpecialContent.get_cms_testimonial!(data.cms_testimonial.id)
    end

    test "delete_cms_testimonial/1 deletes the cms_testimonial", %{data: data} do
      assert {:ok, %CmsTestimonial{}} = SpecialContent.delete_cms_testimonial(data.cms_testimonial)
      assert_raise Ecto.NoResultsError, fn -> SpecialContent.get_cms_testimonial!(data.cms_testimonial.id) end
    end

    test "change_cms_testimonial/1 returns a cms_testimonial changeset", %{data: data} do
      assert %Ecto.Changeset{} = SpecialContent.change_cms_testimonial(data.cms_testimonial)
    end
  end
end
