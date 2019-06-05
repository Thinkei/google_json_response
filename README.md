# GoogleJsonResponse

Parser for APIs following Google JSON style  
Please note that the term "code" in this gem is not HTTP code (obviously you can use it as HTTP code if you want)

## Table of Contents
<!-- TOC depthFrom:1 depthTo:6 withLinks:1 orderedList:0 -->

- [Installation](#installation)
- [Usage](#usage)
    - [Scenario 1: Render Active Model errors](#scenario-1-parse-active-model-errors)
    - [Scenario 2: Render standard errors](#scenario-2-parse-standard-errors)
    - [Scenario 3: Render active records with active model serializers](#scenario-3-parse-active-records-with-active-model-serializers)
    - [Scenario 4: Render a generic error message](#scenario-4-render-a-generic-error-message)
    - [Scenario 5: Render a generic message](#scenario-5-render-a-generic-message)
    - [Scenario 6: Render sequel records with active model serializers](#scenario-6-render-sequel-records-with-active-model-serializers)
    - [Scenario 7: Render a error messages for grape api](#scenario-7-render-a-error-messages-for-grape-api)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
<!-- /TOC -->

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'google_json_response'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install google_json_response
    
Create \<Your project name\>/config/initializers/google_json_response_setup.rb like this:
```
require "google_json_response/active_records" #include this if you want to parse active records or active record errors
```

## Usage
#### Scenario 1: Parse Active Model errors
We will need to require necessary dependencies
```
require "google_json_response/active_records"
```

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
    return GoogleJsonResponse.render_error(service.errors, code: 400).to_json
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
Please check [Service error handling wiki](https://github.com/Thinkei/google_json_response/wiki/Service-error-handling) to know how to handle errors in services with the gem.

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
    render json: GoogleJsonResponse.render_error(service.errors).to_json, status: 500
  end
```

Or render the error at the application layer of Sinatra  
```ruby
  if !service.success?
    return GoogleJsonResponse.render_error(service.errors).to_json
  end
```

Here is what we will have from the above code snippet
```json
{
  "error": {
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
Please check [Date time format for active_model_serializers](https://github.com/Thinkei/google_json_response/wiki/Date-time-format-for-active_model_serializers) to know about how to deal with date time format.  
We will need to require necessary dependencies
```
require "google_json_response/active_records"
```
We can parse a single active record object
```ruby
  GoogleJsonResponse.render(record_1, { serializer_klass: UserSerializer }).to_json
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
  GoogleJsonResponse.render(array_of_records, { serializer_klass: UserSerializer, custom_data: { include: "**" } }).to_json
```

We can parse a active record relation object
```ruby
  GoogleJsonResponse.render(
    User.where(name: 'test'),
    serializer_klass: UserSerializer, custom_data: { sort: '+name', item_per_page: 10 }
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
  GoogleJsonResponse.render_error("You can't access this page").to_json
```
The result will be like this
```json
{
  "error": {
    "errors": [
      {
        "reason": "error",
        "message": "You can't access this page"
      }
    ]
  }
}
```

#### Scenario 5: Render a generic message
We want to render a hash message like a message to notify end-user about submitting a form successfully
```ruby
  GoogleJsonResponse.render({message: 'saved successfully'}).to_json
```
The result will be like this
```json
{
  "data": {
    "message": "saved successfully"
  }
}
```

#### Scenario 6: Render sequel records with active model serializers
Please check [Setup sequel wiki](https://github.com/Thinkei/google_json_response/wiki/Setup-sequel) to know how to integrate Sequel with your app (for example: pagination integration ...)

We will need to require necessary dependencies
```
require "google_json_response/sequel_records"
```

We will need to add method read_attribute_for_serialization to the model we want to render
```
class User < Sequel::Model(SequelDB[:users])
  def read_attribute_for_serialization(name)
    self.values[name]
  end
end
```

We can parse a single sequel record object
```ruby
  GoogleJsonResponse.render(record, { serializer_klass: UserSerializer }).to_json
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

We can parse an array of sequel records
```ruby
  GoogleJsonResponse.render(records_array, { serializer_klass: UserSerializer, custom_data: { include: "**" } }).to_json
```

We can parse a sequel dataset object
```ruby
  GoogleJsonResponse.render(
    User.where(name: 'test'), 
    serializer_klass: UserSerializer, custom_data: { sort: '+name' }
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

#### Scenario 7: Render a error messages for grape api
If you are using grape api, you can use the following code snippet for rendering errors  
```ruby
  error!(GoogleJsonResponse.render_error(['You can't access this page']), 400)
```
The result will be like this  
```json
{
  "error": {
    "errors": [
      {
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

