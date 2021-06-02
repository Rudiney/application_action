class ApplicationAction
  include ActiveModel::Model

  def save
    return false unless valid?

    ApplicationRecord.transaction { run }

    after_run

    return true
  end

  def save!
    raise errors.full_messages.join(', ') unless save
  end

  def run
    raise 'You should write your own #run method'
  end

  def after_run; end
end
