# ApplicationAction

Tiny on code, heavy on concept. ApplicationAction is an opiniated concept extend of the Ruby on Rails framework.

ApplicationAction is an useful `Action` pattern I found myself following for many years among many Rails projects so I hope its usefull for you too. It mimics `ApplicationRecord`'s interface to the `Action`s your applications execute. Its easy to extent, test, compose and reuse.

This is the code. All of it:

```ruby
class ApplicationAction
  include ActiveModel::Model

  def save
    return false unless valid?

    ApplicationRecord.transaction { run }

    return true
  end

  def save!
    raise errors.full_messages.join(', ') unless save
  end

  def run
    raise 'You should write your own #run method'
  end
end
```

## Installation

Add this line to your Gemfile:

```ruby
gem 'application_action'
```

And then execute:

```bash
$ bundle
```

## Usage

`app/actions/some_action.rb`

```ruby
class SomeAction < ApplicationAction
  attr_accessor :foo, :bar

  # write what you need to validate before run the action
  validates :foo, :bar, presence: true
  validate :foo_is_complete, :bar_is_available

  def run
    # what the action should do when its valid
  end

  private

  # the validations
  def foo_is_complete
    errors.add(:foo, :not_complete) unless foo.complete?
  end

  def bar_is_available
    errors.add(:foo, :not_available) unless bar.available?
  end
end
```

Then, whenever suits you, call the action like this:

```ruby
action = SomeAction.new(foo: foo, bar: bar)
action.valid?
action.save
action.save! # raises the validations errors as RuntimeErrors
```

Having being through all the "fat models, skinny controllers" eras, I find an `Action` usefull when I have something my application need to do but no model or controller seem like the right place. It's usually some logic involving multiple models and a different set of validations. Its specially usefull when the same `Action` needs to be called from different entries (e.g. API, WEB Interface, background job, etc).

**`#run` method is atomic** so feel free to change multiple database tables using different models `.create!` or `.update!` that it will all get rolled back if some exception happens. Be sure you create all the validations you need to ensure your `Action` will run with no exception. Its easy to handle validations errors and display messages this way.

## Philosophy

Think of `Action`s as one small state transition of your application. It's the representation of what your application does. So everytime an `Action` run, something changes and there are consequences. Each `Action` have a well-defined and validated scenario before running.

#### The business logic should not live in the models

You heard the story before: `ActiveRecord` already does too much. The database interface, query, validations and relationships are more than enough.

Models should represent an entity stored at the database, a small piece of your entire application state. A single model or record should not handle complex operations, specially involving multiple models.

Models validations should only check what is expected for every record, everytime. Some validations will only be applied in certain moments so these validations lives in an `Action`. [ActiveRecord's validations scope](https://guides.rubyonrails.org/active_record_validations.html#on) can handle simple scenarios but `Action`s validations is a better suit for complex logics.

#### The business logic should not live in controllers

Same here. Controller already handle request params and formats, response codes and authorization. But most important, you should be able to test your business logic without the need of an HTTP request.

#### Actions are important changes

`Action`s should have strict validations to make sure everything is ok before running. `Action`s are atomic, so you must have it completely done, or not done at all. This will help with your database (and the whole app) consistency.

They should be well tested and you should be able to test every scenario without an integration test. You can unit test every `Action` validation and every change it makes when it runs.

### A Practical Example

#### Uber-like Logic

Consider an Uber-like app, where passengers request for trips and the nearest available driver is found. The driver can refuse the request, so the next driver should be requested. Driver also have a 1 minute timeout to respond the request, otherwise it expires and the next driver is called. You can have some _DRY_ `Action`s like these:

1. Request Trip Action:

```ruby
class RequestTrip < ApplicationAction
  attr_accessor :passenger, :pickup_address, :destination_address

  validate :passenger_is_not_blocked
  validate :passenger_is_not_in_debt

  def run
    Trip.create!(
      passenger: passenger,
      pickup_address: pickup_address,
      destination_address: destination_address,
      requested_at: Time.current,
      driver: nil,
      accepted: false
    )

    FindTripDriver.new(trip: trip).save!
  end

  private

  def passenger_is_not_blocked
    #...
  end

  def passenger_is_not_in_debt
    #...
  end
end
```

2. Find a Trip Driver

```ruby
class FindTripDriver < ApplicationAction
  attr_accessor :trip

  validate :trip_is_still_a_request
  validates :nearest_driver, :trip, presence: true

  def nearest_driver
    Driver.available.where(...).first
  end

  def run
    trip.update!(driver: nearest_driver)
    driver.update!(current_trip: trip)
    invite = TripInvitation.create!(trip: trip, driver: driver)

    Notifications::InviteDriverToTrip.new(invite: invite).send!

    # rejects automatically after 1 minute
    DriverRejectTripJob.set(wait: 1.minute).perform_later(invite: invite)
  end

  private

  def trip_is_still_a_request
    errors.add(:trip, :already_accepted) if trip.accepted?
  end
end
```

3. Driver Rejects the request

```ruby
class DriverRejectTrip < ApplicationAction
  attr_accessor :invite

  validates :trip_is_not_already_accepted

  delegate :trip, :driver, to: :invite

  def run
    invite.update!(accepted: false)
    trip.update!(driver: nil)
    driver.update!(current_trip: nil)

    FindTripDriver.new(trip: trip).save! # easy to reuse the action
  end

  private

  def trip_is_not_already_accepted
    #...
  end
end
```

- Note how simple it is to test these actions.
- You can call them at diferent Controllers, from `ActiveJob`s or **GraphQL Mutations**
- Your life at the `rails console` will be a lot easer having a way to call these business logic directly. No need of api calls or web interface.

### Translating error messages

As the `Action`s includes `ActiveModel::Model` you can have each action's error message get translated by following this structure:

```yml
en:
  activemodel:
    attributes:
      find_tripd_river: # <- The action name snake-cased
        driver: Driver
        trip: Trip
    errors:
      models:
        find_tripd_river: # <- The action name snake-cased
          attributes:
            trip:
              already_accepted: "was already accepted." # <- each error message  translation
```

## Inspiration

The experience of building multiple web applications with Rails, including different environments like 100% web interface apps or API only (both REST & GraphQL) apps, a single product with a legacy monorepo maintained by a big team or multiple quickly built on demand projects, made it clear this commom gap of Rails on where to place some more complex business logic. I covered this gap in many different ways in the past. From **Fat Models** to **Fat Controllers**, sometimes as `PORO`s under the `lib` folder and sometimes with different names (as `Services` or `Runners`).

It was after i built some React SPA's and got familiar with the [Flux](https://facebook.github.io/flux/) architecture to handle front-end's application state and later getting used to the [Redux](https://redux.js.org) implementation library that i shamelessly copied the name **Action** as I found it's was a nice fit for the case of a Rails application as well.

I could translate the [Redux's Core Concepts](https://redux.js.org/introduction/core-concepts) and [Principles](https://redux.js.org/introduction/three-principles) to a Rails. I can see the database as the entire application state, the single source of truth and one should avoid change the application's state without an `Action` (specially for big changes). Every `Action` have an explicit changelist on the state so its easy to track how the state was before running and how the state became after.

## Contributing

`bin/rspec spec` to run te spec suit and all PRs are welcome.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
