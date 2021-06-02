require 'rails_helper'

RSpec.describe ApplicationAction do
  it 'includes ActiveModel::Model' do
    expect(ApplicationAction.ancestors).to include ActiveModel::Model
  end

  describe 'saving' do
    class DummyAction < ApplicationAction
      attr_accessor :name
      attr_reader :ran

      validates :name, presence: true

      def run
        @ran = true
      end

      def ran?
        @ran.present?
      end
    end

    it 'only run if its valid' do
      action = DummyAction.new(name: 'foo')
      expect(action).to_not be_ran

      expect(action).to be_valid

      expect(action.save).to be true

      expect(action).to be_ran
    end

    it 'validates before run' do
      action = DummyAction.new
      expect(action).to_not be_ran

      expect(action).to_not be_valid

      expect(action.save).to be false

      expect(action).to_not be_ran
    end

    it 'save! raises the errors' do
      action = DummyAction.new
      expect(action).to_not be_ran

      expect(action).to_not be_valid

      expect { action.save! }.to raise_error(RuntimeError)
    end
  end

  describe 'after_run' do
    class AfterRunDummyAction < ApplicationAction
      attr_accessor :name
      attr_reader :after_ran

      def run; end

      def after_run
        @after_run = true
      end

      def after_ran?
        @after_run.present?
      end
    end

    it 'run after the run' do
      action = AfterRunDummyAction.new(name: 'foo')
      expect(action.after_ran?).to be false

      expect(action).to be_valid
      action.save!

      expect(action.after_ran?).to be true
    end
  end
end
