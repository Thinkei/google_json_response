require "spec_helper"

describe GoogleJsonResponse do
  describe ".render_record" do
    let(:service_double) { double({}) }

    after do
      if Object.const_get(:GoogleJsonResponse).constants.include?(:ParseActiveRecords) 
        Object.const_get(:GoogleJsonResponse).send(:remove_const, :ParseActiveRecords)
      end
    end

    context "data is a ActiveRecord::Base and parse_active_records is required" do
      let!(:record_1) { User.new(key: '1', name: "test") }

      it 'calls ParseErrors with correct params' do
        require "google_json_response/parse_active_records"
        expect(GoogleJsonResponse::ParseActiveRecords).to receive(:new).with(record_1, { serializer: :test }).and_return(service_double)
        expect(service_double).to receive(:call)
        expect(service_double).to receive(:parsed_data).and_return({data: 'test'})
        response = GoogleJsonResponse.render_record(record_1, { serializer: :test })
        expect(response).to eq({data: 'test'})
      end
    end

    context "data is a ActiveRecord::Base and parse_active_records is not required" do
      let!(:record_1) { User.new(key: '1', name: "test") }

      it 'throws runtime errror' do
        expect {
          response = GoogleJsonResponse.render_record(record_1, { serializer: :test })
        }.to raise_error(
               RuntimeError,
               "Please require google_json_response/parse_active_records"\
               " to render active records"
             )
      end
    end
  end

  describe ".render_records" do
    let(:service_double) { double({}) }

    after do
      if Object.const_get(:GoogleJsonResponse).constants.include?(:ParseActiveRecords) 
        Object.const_get(:GoogleJsonResponse).send(:remove_const, :ParseActiveRecords)
      end
    end

    context "data is a ActiveRecord::Relation and parse_active_records is required" do
      let!(:record_1) { User.create(key: '1', name: "test") }
      let!(:record_relation) { User.where(name: "test") }

      it 'calls ParseErrors with correct params' do
        load "google_json_response/parse_active_records.rb"
        expect(GoogleJsonResponse::ParseActiveRecords).to receive(:new).with(record_relation, { serializer: :test }).and_return(service_double)
        expect(service_double).to receive(:call)
        expect(service_double).to receive(:parsed_data).and_return({data: 'test'})
        response = GoogleJsonResponse.render_records(record_relation, { serializer: :test })
        expect(response).to eq({data: 'test'})
      end
    end

    context "data is a ActiveRecord::Relation and parse_active_records is not required" do
      let!(:record_1) { User.create(key: '1', name: "test") }
      let!(:record_relation) { User.where(name: "test") }

      it 'throw runtime error' do
        expect {
          GoogleJsonResponse.render_records(record_relation, { serializer: :test })
        }.to raise_error(
               RuntimeError,
               "Please require google_json_response/parse_active_records"\
               " to render active records"
             )
      end
    end

    context "data is an array of ActiveRecord::Base and parse_active_records is required" do
      let!(:record_1) { User.new(key: '1', name: "test") }
      let!(:record_2) { User.new(key: '2', name: "test") }
      let!(:records) { [record_1, record_2] }

      it 'calls ParseErrors with correct params' do
        load "google_json_response/parse_active_records.rb"
        expect(GoogleJsonResponse::ParseActiveRecords).to receive(:new).with(records, { serializer: :test }).and_return(service_double)
        expect(service_double).to receive(:call)
        expect(service_double).to receive(:parsed_data).and_return({data: 'test'})
        response = GoogleJsonResponse.render_records(records, { serializer: :test })
        expect(response).to eq({data: 'test'})
      end
    end
  end

  describe ".render_error" do
    let!(:test_model) {
      stub_const 'TestModel', Class.new
      TestModel.class_eval do
        include ActiveModel::Validations

        def initialize(attributes = {})
          @attributes = attributes
        end

        def read_attribute_for_validation(key)
          @attributes[key]
        end
      end
      TestModel.new(id: 1, email: "test@test.com", first_name: "a")
    }

    let(:service_double) { double({}) }

    after do
      if Object.const_get(:GoogleJsonResponse).constants.include?(:ErrorParsers) 
        Object.const_get(:GoogleJsonResponse).send(:remove_const, :ErrorParsers)
      end
    end

    context "data is a StandardError and error_parsers is required" do
      let!(:error_1) { StandardError.new("Error 1") }

      it 'calls ParseErrors with correct params' do
        load "google_json_response/error_parsers.rb"
        expect(GoogleJsonResponse::ErrorParsers).to receive(:parse).with(error_1, {}).and_return({data: 'test'})
        response = GoogleJsonResponse.render_error(error_1)
        expect(response).to eq({data: 'test'})
      end
    end

    context "data is a StandardError and error_parsers is not required" do
      let!(:error_1) { StandardError.new("Error 1") }

      it 'throws runtime error' do
        expect {
          GoogleJsonResponse.render_error(error_1)
        }.to raise_error(
               RuntimeError,
               "Please require google_json_response/error_parsers"\
               " to render errors"
             )
      end
    end

    context "data is an array of StandardError and error_parsers is required" do
      let!(:error_1) { StandardError.new("Error 1") }
      let!(:error_2) { StandardError.new("Error 2") }
      let!(:errors) { [error_1, error_2] }

      it 'calls ParseErrors with correct params' do
        load "google_json_response/error_parsers.rb"
        expect(GoogleJsonResponse::ErrorParsers).to receive(:parse).with(errors, {}).and_return({data: 'test'})
        response = GoogleJsonResponse.render_error(errors)
        expect(response).to eq({data: 'test'})
      end
    end

    context "data is a ActiveModel::Errors and error_parsers is required" do
      let!(:errors_1) {
        ActiveModel::Errors.new(test_model)
      }

      it 'calls ParseErrors with correct params' do
        load "google_json_response/error_parsers.rb"
        expect(GoogleJsonResponse::ErrorParsers).to receive(:parse).with(errors_1, {}).and_return({data: 'test'})
        response = GoogleJsonResponse.render_error(errors_1)
        expect(response).to eq({data: 'test'})
      end
    end

    context "data is an array of ActiveModel::Errors and error_parsers is required" do
      let!(:errors_1) {
        ActiveModel::Errors.new(test_model)
      }

      let!(:errors_2) {
        ActiveModel::Errors.new(test_model)
      }

      let!(:errors_array) {
        [errors_1, errors_2]
      }

      it 'calls ParseErrors with correct params' do
        load "google_json_response/error_parsers.rb"
        expect(GoogleJsonResponse::ErrorParsers).to receive(:parse).with(errors_array, {}).and_return({data: 'test'})
        response = GoogleJsonResponse.render_error(errors_array)
        expect(response).to eq({data: 'test'})
      end
    end

     context "data is a string" do
       it 'renders a generic error' do
         response = GoogleJsonResponse.render_error("You can't access this page", code: '401')
         expect(response).to eq({
                                  error:{
                                           code: '401',
                                           errors: [
                                             {
                                               message: "You can't access this page",
                                               reason: 'error'
                                             }
                                           ]
                                         }
                                })
       end
     end
  end

  describe ".render" do
    context "data is a hash" do
      let!(:hash_1) { {message: 'test'} }

      it 'calls ParseErrors with correct params' do
        response = GoogleJsonResponse.render(hash_1, {})
        expect(response).to eq({data: {message: 'test'}})
      end
    end
  end

  it "has a version number" do
    expect(GoogleJsonResponse::VERSION).not_to be nil
  end
end
