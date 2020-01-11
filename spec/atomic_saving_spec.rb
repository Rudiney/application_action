require 'rails_helper'

RSpec.describe CreatePost do
  it 'reverts if there is an exception on the run method' do
    user = User.create!(name: 'foo', posts_count: 0)
    action = CreatePost.new(user: user, post_title: nil)

    expect(Post.count).to eql 0

    expect(action).to be_valid

    expect { action.save }.to raise_error(ActiveRecord::RecordInvalid)

    expect(user.reload.posts_count).to eql 0
    expect(Post.count).to eql 0
  end
end
