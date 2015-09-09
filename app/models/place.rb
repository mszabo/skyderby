# == Schema Information
#
# Table name: places
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  latitude    :decimal(15, 10)
#  longitude   :decimal(15, 10)
#  information :text(65535)
#  country_id  :integer
#  msl         :integer
#

class Place < ActiveRecord::Base
  belongs_to :country

  has_many :tracks, -> { order('created_at DESC') }
  has_many :public_tracks,
           -> { where(visibility: 0).order('created_at DESC') },
           class_name: 'Track'
  has_many :pilots, through: :tracks
  has_many :events

  validates :name, presence: true
  validates :country, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true
  validates :msl, presence: true

  class << self
    def search(query)
      joins(:country).where(
        'LOWER(places.name) LIKE :query OR LOWER(countries.name) LIKE :query',
        query: "%#{query.downcase}%"
      )
    end

    def nearby(point, radius)
      select('id,
              latitude,
              longitude,
              msl,
              SQRT(
                POW(111 * (latitude - ' + point.latitude.to_s + '), 2) +
                POW(111 * (' + point.longitude.to_s + ' - longitude) * COS(latitude / (180/PI()) ), 2)
              ) AS distance')
        .having('distance < :radius', radius: radius)
        .order('distance DESC')
    end
  end
end
