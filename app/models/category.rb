class Category < ActiveRecord::Base
  has_many :posts
  has_many :screen_casts
  has_many :trainings
  scope :from_posts, -> {
    all.inject([]){|array, c|
      if c.posts.count > 0
        array.push c
      else
        array
      end
    }
  }
end
