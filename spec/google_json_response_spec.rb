require "spec_helper"

describe GoogleJsonResponse do
  describe 'Active Record rendering' do
    let!(:record) { User.create(key: '1', name: "test") }
    let!(:record_relation) { User.where(name: "test") }

    context "parse_active_records is not loaded" do
      it 'throws runtime errror' do
        expect {
          GoogleJsonResponse.render(record)
        }.to raise_error(
               RuntimeError,
               "Please require google_json_response/active_records"\
               " to render active records"
             )
      end
    end

    context 'parse_active_records is loaded' do
      before { require 'google_json_response/record_parsers/parse_active_records' }

      context "render single record" do
        context "data is a ActiveRecord::Base and parse_active_records is required" do
          it 'correctly renders active record with serializer' do
            response = GoogleJsonResponse.render(record, serializer_klass: UserSerializer)
            expect(response).to eq({ data: { key: '1', name: 'test' } })
          end
        end
      end

      context "render record collections" do
        context "data is a ActiveRecord::Relation and parse_active_records is required" do
          it 'calls ParseActiveRecords with correct params' do
            response = GoogleJsonResponse.render(record_relation, { serializer_klass: UserSerializer })
            expect(response.dig(:data, :items)).to eq ([{ key: "1", name: "test" }])
          end
        end

        context "data is an array of ActiveRecord::Base and parse_active_records is required" do
          let!(:second_record) { User.new(key: '2', name: "test") }
          let!(:records) { [record, second_record] }

          it 'calls ParseActiveRecords with correct params' do
            response = GoogleJsonResponse.render(records, { serializer_klass: UserSerializer })
            expect(response.dig(:data, :items))
              .to eq([{ key: "1", name: "test" }, { key: "2", name: "test" }])
          end
        end
      end
    end
  end

  describe "Sequel Record Rendering" do
    let(:record_relation) { Item.where(name: 'test') }
    let(:record) { record_relation.first }

    before do
      @items = SequelDB[:items] # Create a dataset
      @items.delete
      @items.insert(name: 'test', code: '1')
    end

    context "parse_sequel_records is not included" do
      it 'throws an error' do
        expect {
          GoogleJsonResponse.render(record)
        }.to raise_error(
               RuntimeError,
               "Please require google_json_response/sequel_records"\
               " to render sequel records"
             )
      end
    end

    context 'parse_sequel_records is included' do
      before do
        load "google_json_response/record_parsers/parse_sequel_records.rb"
      end

      it "correctly renders a data set" do
        response = GoogleJsonResponse.render(record_relation, { serializer_klass: ItemSerializer })
        expect(response.dig(:data, :items)).to eq ([{ code: "1", name: "test" }])
      end

      it "correctly renders a single record" do
        response = GoogleJsonResponse.render(record, { serializer_klass: ItemSerializer })
        expect(response).to eq({ data: { code: '1', name: 'test' } })
      end

      context 'Array of Sequel::Model' do
        before do
          @items = SequelDB[:items] # Create a dataset
          @items.insert(name: 'test', code: '2')
        end

        let!(:second_record) { Item.where(code: '2').first }
        let!(:records) { [record, second_record] }

        it 'render correctly' do
          response = GoogleJsonResponse.render(records, { serializer_klass: ItemSerializer })
          expect(response.dig(:data, :items))
            .to eq([{ code: "1", name: "test" }, { code: "2", name: "test" }])
        end
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

    context "data is a StandardError" do
      let!(:error) { StandardError.new("Error 1") }

      it 'calls ParseErrors with correct params' do
        response = GoogleJsonResponse.render_error(error)
        expect(response)
          .to eq({ error: { errors: [{ message: "Error 1", reason: "StandardError" }] } })
      end
    end

    context "data is an array of StandardError" do
      let!(:error_1) { StandardError.new("Error 1") }
      let!(:error_2) { StandardError.new("Error 2") }
      let!(:errors) { [error_1, error_2] }

      it 'calls ParseErrors with correct params' do
        response = GoogleJsonResponse.render_error(errors)
        expect(response)
          .to eq({ error: { errors: [{ message: "Error 1" }, { message: "Error 2" }] } })
      end
    end

    context 'ActiveModel::Error' do
      let!(:error) { ActiveModel::Errors.new(test_model) }

      context "Single model error" do
        before { error.add(:email, 'error') }

        it 'render correct error contents' do
          response = GoogleJsonResponse.render_error(error)
          expect(response)
            .to eq({ error:
                       { errors: [
                         {
                           location: :email,
                           location_type: :field,
                           message: "Email error",
                           reason: "error"
                         }
                       ] }
                   })
        end
      end

      context "multiple error contexts" do
        before do
          error.add(:email, 'error')
          error.add(:name, 'error')
        end

        it 'calls ParseErrors with correct params' do
          response = GoogleJsonResponse.render_error(error)
          expect(response).to eq({ error: { errors: [
            { location: :email, location_type: :field, message: "Email error", reason: "error" },
            { location: :name, location_type: :field, message: "Name error", reason: "error" }
          ] } })
        end
      end
    end

    context "data is a string" do
      it 'renders a generic error' do
        response = GoogleJsonResponse.render_error("You can't access this page")
        expect(response)
          .to eq({ error: { errors: [{ message: "You can't access this page" }] } })
      end
    end
  end

  it "has a version number" do
    expect(GoogleJsonResponse::VERSION).not_to be nil
  end
end
