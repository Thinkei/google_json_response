# GoogleJsonResponse

Parser for APIs following Google JSON style

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'google_json_response'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install google_json_response

## Usage
#### Scenario 1: Parse Active Model errors
We have model User and we have the error handling for model User in CreateUser service
```ruby
  @user = User.new(params)
  if !@user.save
    @errors.push(user.errors)
  end
```
Now we want to render the error at the application layer (Rails controller for example)
```ruby
  if !service.success?
    return GoogleJsonResponse.parse(service.errors, code: 400).to_json
  end
```
Here is what we will have from the above code snippet
```json
{
  "error": {
    "code": "400",
    "errors": [
      {
        "reason": "invalid",
        "message": "Email is invalid",
        "location": "email",
        "location_type": "field"
      }
    ]
  }
}
```

#### Scenario 2: Parse standard errors
We have a product purchasing service and we want to handling out of stock error.
We create a custom error class.
```ruby
  class OutOfStockError < StandardError
    def code
      'out_of_stock'
    end
  end
```
We use the custom error class in our purchasing service.

```ruby
  if out_of_stock?
    @errors.push(OutOfStockError.new("Out out stock! Please come back later."))
  end
```

Now we want to render the error at the application layer (Rails controller for example)
```ruby
  if !service.success?
    return GoogleJsonResponse.parse(service.errors, code: 400).to_json
  end
```
Here is what we will have from the above code snippet
```json
{
  "error": {
    "code": "400",
    "errors": [
      {
        "reason": "out_of_stock",
        "message": "Out out stock! Please come back later.",
      }
    ]
  }
}
```

#### Scenario 3: Parse active records with active model serializers
We can parse a single active record object
```ruby
  GoogleJsonResponse.parse(record_1, { serializer_klass: UserSerializer }).to_json
```

The result will be like this

```json
{
  "data": {
    "key": "1",
    "name": "test"
  }
}
```

We can parse an array of active records
```ruby
  GoogleJsonResponse.parse([record_1, record_2, record_3], { serializer_klass: UserSerializer, include: "**" }).to_json
```

We can parse a active record relation object
```ruby
  GoogleJsonResponse.parse(
    User.where(name: 'test'), 
    { serializer_klass: UserSerializer, api_params: { sort: '+name', item_per_page: 10 } }
  ).to_json
```

The result will be like this
```json
{
  "data": {
    "sort": "+name",
    "item_per_page": 10,
    "page_index": 1,
    "total_pages": 1,
    "total_items": 3,
    "items": [
      {
        "key": "1",
        "name": "test"
      },
      {
        "key": "2",
        "name": "test"
      },
      {
        "key": "3",
        "name": "test"
      }
    ]
  }
}

```

#### Scenario 4: Render a generic error message
Sometimes we will need to render a simple error message at application layer
```ruby
  GoogleJsonResponse.render_generic_error("You can't access this page", '401').to_json
```
The result will be like this
```json
{
  "error": {
    "code": "401",
    "errors": [
      {
        "reason": "error",
        "message": "You can't access this page"
      }
    ]
  }
}
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/google_json_response.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

