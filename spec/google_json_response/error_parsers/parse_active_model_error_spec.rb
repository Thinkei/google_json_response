require "spec_helper"

describe GoogleJsonResponse::ErrorParsers::ParseActiveModelError do
  describe "#call" do
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
    let!(:errors) {
      ActiveModel::Errors.new(test_model)
    }
    context "there's only 1 default error message" do
      before do
        errors.add(:email, :invalid, value: "test2")
      end

      it "renders correctly and the message should not be filtered" do
        parser = GoogleJsonResponse::ErrorParsers::ParseActiveModelError.new(errors, code: 200)
        parser.call
        result = parser.parsed_data
        expect(result[:error]).to include(code: '200')
        expect(result[:error])
          .to include(errors: [
                                  {
                                    reason: :invalid,
                                    message: "Email is invalid",
                                    location: :email,
                                    location_type:  :field
                                  }
                                ])
      end
    end

    context 'render custom error message' do
      context 'with field name in the message' do
        before do
          errors.add(:email, :invalid, value: "test2", message: "is incorrect")
        end

        it "renders correctly" do
          parser = GoogleJsonResponse::ErrorParsers::ParseActiveModelError.new(errors, code: 200)
          parser.call
          result = parser.parsed_data
          expect(result[:error]).to include(code: '200')
          expect(result[:error])
            .to include(errors: [
                                    {
                                      reason: :invalid,
                                      message: "Email is incorrect",
                                      location: :email,
                                      location_type: :field
                                    }
                                  ])
        end
      end

      context 'without field name in the message by using ^' do
        before do
          errors.add(:email, :invalid, value: "test2", message: "^Email format is invalid")
        end

        it "renders correctly" do
          parser = GoogleJsonResponse::ErrorParsers::ParseActiveModelError.new(errors, code: 200)
          parser.call
          result = parser.parsed_data
          expect(result[:error]).to include(code: '200')
          expect(result[:error])
            .to include(errors: [
                                    {
                                      reason: :invalid,
                                      message: "Email format is invalid",
                                      location: :email,
                                      location_type: :field
                                    }
                                  ])
        end
      end
    end

    context "render with the 'in valid' default message mixed with the custom message" do
      before do
        errors.add(:email, :invalid, value: "test2")
        errors.add(:email, :invalid, value: "test2", message: "^Email format is invalid")
        errors.add(:email, :invalid, value: "test2", message: "^Other custom message")
      end

      it "keeps the custom messages and removes the default message" do
        parser = GoogleJsonResponse::ErrorParsers::ParseActiveModelError.new(errors, code: 200)
        parser.call
        result = parser.parsed_data
        expect(result[:error]).to include(code: '200')
        expect(result[:error])
          .to include(errors: [
                                  {
                                    reason: :invalid,
                                    message: "Email format is invalid",
                                    location: :email,
                                    location_type: :field
                                  },
                                  {
                                    reason: :invalid,
                                    message: "Other custom message",
                                    location: :email,
                                    location_type: :field
                                  }
                                ])
      end
    end
  end
end
