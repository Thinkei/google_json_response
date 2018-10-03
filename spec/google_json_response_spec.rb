require "spec_helper"

describe GoogleJsonResponse do
  describe ".parse" do
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

    context "data is a StandardError" do
      let!(:error_1) { StandardError.new("Error 1") }

      it 'calls ParseErrors with correct params' do
        expect(GoogleJsonResponse::ParseErrors).to receive(:new).with(error_1, {}).and_return(service_double)
        expect(service_double).to receive(:call)
        expect(service_double).to receive(:parsed_data).and_return({data: 'test'})
        response = GoogleJsonResponse.parse(error_1)
        expect(response).to eq({data: 'test'})
      end
    end

    context "data is an array of StandardError" do
      let!(:error_1) { StandardError.new("Error 1") }
      let!(:error_2) { StandardError.new("Error 2") }
      let!(:errors) { [error_1, error_2] }

      it 'calls ParseErrors with correct params' do
        expect(GoogleJsonResponse::ParseErrors).to receive(:new).with(errors, {}).and_return(service_double)
        expect(service_double).to receive(:call)
        expect(service_double).to receive(:parsed_data).and_return({data: 'test'})
        response = GoogleJsonResponse.parse(errors)
        expect(response).to eq({data: 'test'})
      end
    end

    context "data is a ActiveModel::Errors" do
      let!(:errors_1) {
        ActiveModel::Errors.new(test_model)
      }

      it 'calls ParseErrors with correct params' do
        expect(GoogleJsonResponse::ParseErrors).to receive(:new).with(errors_1, {}).and_return(service_double)
        expect(service_double).to receive(:call)
        expect(service_double).to receive(:parsed_data).and_return({data: 'test'})
        response = GoogleJsonResponse.parse(errors_1)
        expect(response).to eq({data: 'test'})
      end
    end

    context "data is an array of ActiveModel::Errors" do
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
        expect(GoogleJsonResponse::ParseErrors).to receive(:new).with(errors_array, {}).and_return(service_double)
        expect(service_double).to receive(:call)
        expect(service_double).to receive(:parsed_data).and_return({data: 'test'})
        response = GoogleJsonResponse.parse(errors_array)
        expect(response).to eq({data: 'test'})
      end
    end

    context "data is a ActiveRecord::Base" do
      let!(:record_1) { User.new(key: '1', name: "test") }

      it 'calls ParseErrors with correct params' do
        expect(GoogleJsonResponse::ParseActiveRecords).to receive(:new).with(record_1, { serializer: :test }).and_return(service_double)
        expect(service_double).to receive(:call)
        expect(service_double).to receive(:parsed_data).and_return({data: 'test'})
        response = GoogleJsonResponse.parse(record_1, { serializer: :test })
        expect(response).to eq({data: 'test'})
      end
    end

    context "data is a ActiveRecord::Relation" do
      let!(:record_1) { User.create(key: '1', name: "test") }
      let!(:record_relation) { User.where(name: "test") }

      it 'calls ParseErrors with correct params' do
        expect(GoogleJsonResponse::ParseActiveRecords).to receive(:new).with(record_relation, { serializer: :test }).and_return(service_double)
        expect(service_double).to receive(:call)
        expect(service_double).to receive(:parsed_data).and_return({data: 'test'})
        response = GoogleJsonResponse.parse(record_relation, { serializer: :test })
        expect(response).to eq({data: 'test'})
      end
    end

    context "data is an array of ActiveRecord::Base" do
      let!(:record_1) { User.new(key: '1', name: "test") }
      let!(:record_2) { User.new(key: '2', name: "test") }
      let!(:records) { [record_1, record_2] }

      it 'calls ParseErrors with correct params' do
        expect(GoogleJsonResponse::ParseActiveRecords).to receive(:new).with(records, { serializer: :test }).and_return(service_double)
        expect(service_double).to receive(:call)
        expect(service_double).to receive(:parsed_data).and_return({data: 'test'})
        response = GoogleJsonResponse.parse(records, { serializer: :test })
        expect(response).to eq({data: 'test'})
      end
    end

    context "data is a hash" do
      let!(:hash_1) { {message: 'test'} }

      it 'calls ParseErrors with correct params' do
        expect(GoogleJsonResponse::ParseHash).to receive(:new).with(hash_1, {}).and_return(service_double)
        expect(service_double).to receive(:call)
        expect(service_double).to receive(:parsed_data).and_return({data: 'test'})
        response = GoogleJsonResponse.parse(hash_1, {})
        expect(response).to eq({data: 'test'})
      end
    end
  end

  describe ".render_generic_error" do
    it 'renders error correctly' do
      response = GoogleJsonResponse.render_generic_error("You can't access this page", '401')
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

  it "has a version number" do
    expect(GoogleJsonResponse::VERSION).not_to be nil
  end
end
