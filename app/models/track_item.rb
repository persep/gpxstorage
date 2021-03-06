class TrackItem < ApplicationRecord
  include TrackLen

  belongs_to   :track, primary_key: :code, foreign_key: :track_code
  validates    :name, :presence => true, :length => { :maximum => 255 }
  validates    :color, :presence => true, :length => { :maximum => 20 }
  alias_method :update_id, :id

  def code; end
end
