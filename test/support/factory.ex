defmodule DeadSimpleCms.Factory do
  @moduledoc """
  Factories for test setup
  """

  use ExMachina.Ecto, repo: DeadSimpleCms.Repo

  # associations are inserted when you call `insert`
  # comments: [build(:comment)],
  # author: build(:user),

  def base_setup do
    cms_image = insert(:cms_image)
    cms_page = insert(:cms_page)
    cms_content_area = insert(:cms_content_area, cms_page_id: cms_page.id, cms_image_id: cms_image.id)
    cms_bio = insert(:cms_bio, cms_image_id: cms_image.id)

    %{
      cms_image: cms_image,
      cms_page: cms_page,
      cms_content_area: cms_content_area,
      cms_bio: cms_bio
    }
  end

  def cms_page_factory do
    base = sequence(:cms_page_title, &"Home Page #{&1}")

    %DeadSimpleCms.Cms.CmsPage{
      title: base,
      slug: DeadSimpleCms.Slug.normalize(base),
      published: true,
      published_at: DateTime.utc_now()
    }
  end

  def cms_image_factory do
    %DeadSimpleCms.Cms.CmsImage{
      filename: sequence(:cms_image_filename, &"image-#{&1}.jpg"),
      url: sequence(:cms_image_url, &"https://example-bucket.s3.amazonaws.com/dead_simple_cms/images/#{&1}.jpg"),
      alt: "Example image",
      caption: "Example caption",
      width: 1200,
      height: 800,
      content_type: "image/jpeg",
      size: 1_229_955
    }
  end

  def cms_content_area_factory do
    %DeadSimpleCms.Cms.CmsContentArea{
      position: sequence(:cms_content_area_position, &(&1 * 10)),
      name: sequence(:cms_content_area_name, &"area_#{&1}"),
      visible: true,
      title: sequence(:cms_content_area_title, &"Content Area #{&1}"),
      subtitle: "Optional subtitle",
      body_md: "Some **markdown** content.\n\n- One\n- Two\n"
    }

    # cms_page_id
    # cms_image_id
  end

  def cms_bio_factory do
    %DeadSimpleCms.SpecialContent.CmsBio{
      name: "James Bond",
      job_title: "Secret Agent",
      tag_line: "Licensed to charm, fight, and disappear",
      description: "James Bond is a highly skilled intelligence operative known for his calm under pressure, strategic thinking, and ability to adapt in the most dangerous situations. With a reputation for precision, confidence, and style, he has handled high-stakes missions across the globe while maintaining an unmistakable presence and polished professionalism.",
      phone_number: "007-000-0007",
      email: "james.bond@mi6.co.uk",
      facebook: "https://facebook.com/jamesbond",
      instagram: "https://instagram.com/007",
      tik_tok: "https://tiktok.com/@007",
      linked_in: "https://www.linkedin.com/in/jamesbond",
      slug: sequence(:cms_bio_slug, &"james-bond-#{&1}"),
      visible: true
    }

    # cms_image_id
  end
end
