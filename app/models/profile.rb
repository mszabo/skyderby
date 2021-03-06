# == Schema Information
#
# Table name: profiles
#
#  id                   :integer          not null, primary key
#  last_name            :string(510)
#  first_name           :string(510)
#  name                 :string(510)
#  userpic_file_name    :string(510)
#  userpic_content_type :string(510)
#  userpic_file_size    :integer
#  userpic_updated_at   :datetime
#  user_id              :integer
#  facebook_profile     :string(510)
#  vk_profile           :string(510)
#  dropzone_id          :integer
#  crop_x               :integer
#  crop_y               :integer
#  crop_w               :integer
#  crop_h               :integer
#  default_units        :integer          default(0)
#  default_chart_view   :integer          default(0)
#  country_id           :integer
#

class Profile < ActiveRecord::Base
  enum default_units: [:metric, :imperial]
  enum default_chart_view: [:multi, :single]

  belongs_to :user
  belongs_to :country

  has_many :tracks, -> { order('created_at DESC') }
  has_many :public_tracks,
           -> { where(visibility: 0).order('created_at DESC') },
           class_name: 'Track'
  has_many :badges
  has_many :event_organizers

  has_attached_file :userpic,
                    styles: { large: '500x500>',
                              medium: '150x150#',
                              thumb: '32x32#' },
                    default_url: '/images/:style/missing.png'

  delegate :name, to: :country, prefix: true, allow_nil: true
  delegate :code, to: :country, prefix: true, allow_nil: true

  validates_attachment_content_type :userpic, content_type:
    ['image/jpeg', 'image/jpg', 'image/png']

  # Возвращает массив ID соревнований в которых является организатором
  def organizer_of_events
    event_organizers.pluck(:event_id)
  end

  def place_in_ratings
    results =
      VirtualCompResult
      .joins(:virtual_competition)
      .group(:profile_id,
             :virtual_competition_id,
             'virtual_competition_name')
      .order(:virtual_competition_id, 'result DESC')
      .pluck_to_hash(
        'virtual_competitions.name as virtual_competition_name',
        :virtual_competition_id,
        :profile_id,
        'MAX(result) as result')

    grouped = results.group_by { |x| x[:virtual_competition_id] }
    grouped.each do |_, res|
      place = 1
      res.each do |r|
        r[:place] = place
        place += 1
      end
    end

    grouped.map { |x| x.last.detect { |r| r[:profile_id] == id } }.compact
  end

  class << self
    def search(query)
      where('LOWER(profiles.name) LIKE LOWER(?)', "%#{query}%")
    end
  end
end
