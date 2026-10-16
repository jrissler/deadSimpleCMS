defmodule DeadSimpleCmsWeb.Temp.PageTemplates do
  @moduledoc """
  Module for configuring page templates, maybe more...
  """

  def sales_page do
    [
      # Hero – primary pitch (text)
      %{
        position: 10,
        name: "hero_intro",
        title: "Rocket Launch Charters",
        subtitle: "Ultimate Private Viewing Experience",
        body_md: """
        Book an exclusive rocket launch charter aboard our **74ft Hatteras Motor Yacht _Empire_**.
        Escape the crowds and enjoy panoramic, unobstructed views of rocket launches from **Kennedy Space Center** — all from the comfort of a private luxury yacht.

        Experience history from the water with first-class service, comfort, and a one-of-a-kind vantage point you simply cannot get on land.
        """
      },

      # Hero images (image-only areas)
      %{
        position: 20,
        name: "hero_image_left",
        title: "upload_image_here",
        subtitle: nil,
        body_md: nil,
        image_id: nil
      },
      %{
        position: 30,
        name: "hero_image_right",
        title: "upload_image_here",
        subtitle: nil,
        body_md: nil,
        image_id: nil
      },

      # Why choose – intro
      %{
        position: 40,
        name: "why_choose_intro",
        title: "Why Choose a Rocket Launch Charter?",
        subtitle: nil,
        body_md: """
        Rocket launch charters offer the most thrilling and private way to witness spaceflight.
        Unlike crowded public viewing areas, your yacht provides a relaxed, uncrowded, and unforgettable experience — designed entirely around your group.
        """
      },

      # Why choose – benefits (left)
      %{
        position: 50,
        name: "why_choose_left",
        title: nil,
        subtitle: nil,
        body_md: """
        - Unobstructed views of rocket launches from the privacy of our 74ft yacht
        - Spacious flybridge and deck areas designed for comfort and relaxation
        - Luxury amenities onboard, including shaded seating and climate-controlled interiors
        - Flexible charter lengths: half-day, full-day, or custom experiences
        - A serene alternative to crowded causeways and public parks
        """
      },

      # Why choose – benefits (right)
      %{
        position: 60,
        name: "why_choose_right",
        title: nil,
        subtitle: nil,
        body_md: """
        - Professional **USCG-licensed captain and crew** dedicated to safety and service
        - Complimentary charcuterie and non-alcoholic drinks included
        - Catering upgrades and private chef experiences available upon request
        - Fully private group experience — your party only, no strangers onboard
        - Live updates and guidance from our crew before and during the launch
        """
      },

      # Primary CTA
      %{
        position: 70,
        name: "primary_cta",
        title: "Book Your Rocket Launch Charter Today",
        subtitle: nil,
        body_md: """
        Availability is limited around major missions, and launch windows fill quickly.
        Secure your private viewing experience now and enjoy the next rocket launch from the best seat on Florida’s Space Coast.
        """
      },

      # What's included – intro
      %{
        position: 80,
        name: "included_intro",
        title: "What’s Included in Your Space Launch Charter",
        subtitle: "Every charter is designed to deliver a first-class experience with premium service and unmatched views.",
        body_md: nil
      },

      # What's included – features
      %{
        position: 90,
        name: "included_features",
        title: nil,
        subtitle: nil,
        body_md: """
        **Fuel / Yacht**
        Your charter includes all fuel and exclusive use of our 74ft Hatteras Motor Yacht _Empire_, offering spacious viewing decks and refined interiors.

        **Charcuterie and Drinks**
        Complimentary charcuterie and non-alcoholic beverages are included. Catering and bar upgrades are available upon request.

        **Professional Crew**
        Every charter is captained by a licensed USCG Master Captain with years of experience, supported by a professional and attentive crew.

        **Private Group Access**
        Charters are reserved exclusively for your group, providing a truly private and stress-free experience.
        """
      },

      # Important information / disclaimers
      %{
        position: 100,
        name: "important_info",
        title: "Important Information About Rocket Launch Charters",
        subtitle: nil,
        body_md: """
        - **Launch Scrubs & Cancellations:** Rocket launches may be delayed or scrubbed at any time due to technical issues, weather, or mission adjustments.
        - **Weather Impacts:** Wind, rain, lightning, or sea conditions may affect departures or routes.
        - **Vessel Maintenance:** While the yacht is maintained to the highest standards, unforeseen issues may require itinerary adjustments.
        - **Timing & Itinerary Changes:** Launch schedules are controlled by NASA, SpaceX, Blue Origin, and others and may change with little notice.
        - **Capacity & Group Adjustments:** Charters are private to your group; any changes will always be communicated in advance.
        - **Viewing Experience:** Visibility may vary based on weather and rocket trajectory. Clear views are not guaranteed.
        - **Safety First:** Crew instructions must be followed at all times to ensure the safety of all guests.
        """
      }
    ]
  end
end
