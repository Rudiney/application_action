require 'rails_helper'

RSpec.describe ApplicationAction do
  it 'includes ActiveModel::Model' do
    expect(ApplicationAction.ancestors).to include ActiveModel::Model
  end
end
