class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :trackable, :validatable,
  :omniauthable, omniauth_providers: [:facebook]

  has_many :reviews
  has_many :bars, through: :reviews
  has_many :friendships
  has_many :friends, through: :friendships
  has_many :inverse_friendships, class_name: "Friendship", foreign_key: "friend_id"
  has_many :inverse_friends, through: :inverse_friendships, source: :user

  def self.new_with_session(params,session)
    if session["devise.user_attributes"]
      new(session["devise.user_attributes"],without_protection: true) do |user|
        user.attributes = params
        user.valid?
      end
    else
      super
    end
  end

  def self.from_omniauth(auth, current_user)
    authorization = Authorization.where(:provider => auth.provider, :uid => auth.uid.to_s, :token => auth.credentials.token, :secret => auth.credentials.secret).first_or_initialize
    if authorization.user.blank?
      user = current_user || User.where('email = ?', auth["info"]["email"]).first
      if user.blank?
       user = User.new
       user.password = Devise.friendly_token[0,10]
       user.name = auth.info.name
       user.email = auth.info.email
       user.save
     end

     authorization.username = auth.info.nickname
     authorization.user_id = user.id
     authorization.save
   end
   authorization.user
 end

 def find_friendship(user)
    current_user ? Friendship.find(user: user, friend: current_user) || Friendship.find(user: current_user, friend: user) : nil
  end
end
