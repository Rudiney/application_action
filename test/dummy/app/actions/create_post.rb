class CreatePost < ApplicationAction
  attr_accessor :user, :post_title

  def run
    current_count = (user.posts_count || 0)
    user.update!(posts_count: current_count + 1)

    Post.create!(user: user, title: post_title)
  end
end
