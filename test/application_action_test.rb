require 'test_helper'

class ApplicationAction::Test < ActiveSupport::TestCase
  test 'Application Action includes ActiveModel::Model' do
    assert ApplicationAction.ancestors.include?(ActiveModel::Model)
  end
end
