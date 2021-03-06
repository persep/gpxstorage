class User < ActiveRecord::Base
  include LibSupport::BaseObject
  include Attachment::Attachable
  include Attachment::Avatar

  devise      :database_authenticatable, :rememberable, :trackable,
              :omniauthable, :omniauth_providers => [:google_oauth2, :yandex]

  validates   :name, :presence => true, :length => { :maximum => 255 }
  validates   :email, :presence => true, :uniqueness => true

  strip_attributes :only => [:name, :email]
  set_ref_columns  :avatar, :name, :cc
  set_form_columns :name, :admin
  paginates_per    10

  has_many :tracks
  after_commit(:on => :create) { UserMailer.delay.new_user(id) }

  def self.find_for_oauth2(access_token, signed_in_resource = nil)
    data = access_token.info
    user = User.where(:provider => access_token.provider, :uid => access_token.uid).first || \
           User.where(:email => access_token.info.email).first || \
           User.new(:password => Devise.friendly_token[0, 20])

    user.update :name => data['name'], :provider => access_token.provider, :email => data['email'], :uid => access_token.uid
    user.load_avatar(access_token)
    user
  end

  def load_avatar(data)
    img = nil

    case data['provider']
      when 'google_oauth2'
        img = data['info']['image'].sub('s32-c', 's200-c')
      when 'yandex'
        img = "http://avatars.mds.yandex.net/get-yapic/#{data['extra']['raw_info']['default_avatar_id']}/islands-200"
      else nil
    end

    return unless img
    avatar.destroy if avatar

    attach = Attach.add('avatar.jpg', Net::HTTP.get(URI(img)), self)
    self.attaches = [ attach.code ]
    self.avatar_code = attach.code
  end

  # can change only yourself unless you're admin
  def permit_modify?(*opts)
    user = Permissions.extract_user(*opts)
    user && (user.admin? || user.get_id == get_id)
  end

  def refresh_cache
    update :cc => tracks.count
  end

end
