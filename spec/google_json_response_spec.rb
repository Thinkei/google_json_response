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

  describe "Generic Record Rendering" do
    context "data is a string" do
      let(:string) { "This is a String" }
      let(:result) {
        { data:
            {
              item_per_page: nil,
              items: "This is a String",
              page_index: nil,
              total_items: nil,
              total_pages: nil
            }
        }.with_indifferent_access
      }

      it 'parse correctly' do
        response = GoogleJsonResponse.render(string).with_indifferent_access
        expect(response).to eq result
      end
    end

    context "data is a hash" do
      let(:hash) { { message: 'test' } }
      let(:result) { { data: { message: 'test' } }.with_indifferent_access }

      it 'parse correctly with correct params' do
        response = GoogleJsonResponse.render(hash, {}).with_indifferent_access
        expect(response).to eq result
      end
    end

    context 'data is an array of hash' do
      let(:hash_array) { [{ message: 'test', source: 'human' }] }
      let(:result) {
        {
          data: {
            item_per_page: nil,
            items: [{ message: "test", source: "human" }],
            key: "value",
            page_index: nil,
            total_items: nil,
            total_pages: nil
          }
        }.with_indifferent_access
      }

      it 'parse correctly with correct params' do
        response = GoogleJsonResponse.render(hash_array, custom_data: { key: 'value' }).with_indifferent_access
        expect(response).to eq result
      end
    end
  end

  describe "Standard Error Rendering" do
    context "data is a StandardError" do
      let!(:error) { StandardError.new("Error") }

      context 'render without code' do
        it 'calls ParseErrors with correct params' do
          response = GoogleJsonResponse.render_error(error)
          expect(response)
            .to eq({ error: { errors: [{ message: "Error", reason: "StandardError" }] } })
        end
      end

      context 'render with code' do
        it 'calls ParseErrors with correct params' do
          response = GoogleJsonResponse.render_error(error, code: 'CustomCode')
          expect(response)
            .to eq({ error: { code: 'CustomCode', errors: [{ message: "Error", reason: "StandardError" }] } })
        end
      end
    end

    context "data is an array of StandardError" do
      let!(:error_1) { StandardError.new("Error 1") }
      let!(:error_2) { StandardError.new("Error 2") }
      let!(:errors) { [error_1, error_2] }

      it 'calls ParseErrors with correct params' do
        response = GoogleJsonResponse.render_error(errors, code: 69)
        expect(response)
          .to eq({ error: { code: 69, errors: [{ message: "Error 1", :reason=>"StandardError" }, { message: "Error 2", :reason=>"StandardError" }] } })
      end
    end
  end

  describe "Active Model Errors Rendering" do
    context 'ActiveModel::Error' do
      before do
        require 'active_model'
        require 'google_json_response/active_records'
        require 'active_model/errors_details'
      end

      let!(:record) { User.new(key: nil, name: "test") }

      before do
        record.save
      end

      let!(:error) { record.errors }

      context "Single model error" do

        it 'render correct error contents' do
          response = GoogleJsonResponse.render_error(error)
          expect(response)
            .to eq({ error:
                       { errors: [
                         {
                           location: :key,
                           location_type: :field,
                           message: 'Please select an key before you submit',
                           reason: :blank
                         }
                       ] }
                   })
        end

        context "Render with code" do
          it 'render correct error contents' do
            response = GoogleJsonResponse.render_error(error, code: "CustomCode")
            expect(response)
              .to eq({ error:
                         {
                           code: "CustomCode",
                           errors: [{
                                      location: :key,
                                      location_type: :field,
                                      message: 'Please select an key before you submit',
                                      reason: :blank
                                    }]
                         }
                     })
          end
        end

        context "Render with real model" do
          let!(:record) { User.new(key: nil, name: "test") }

          context "Include field name" do
            it 'render correct error contents' do
              record.save
              response = GoogleJsonResponse.render_error(record.errors, active_record_full_message: true, code: 69)
              expect(response)
                .to eq({ error:
                           { code: 69,
                             errors: [
                               {
                                 location: :key,
                                 location_type: :field,
                                 message: "Key Please select an key before you submit",
                                 reason: :blank
                               }
                             ] }
                       })
            end
          end

          context "Not include field name" do
            it 'render correct error contents' do
              record.save
              response = GoogleJsonResponse.render_error(record.errors)
              expect(response)
                .to eq({ error:
                           { errors: [
                               {
                                 location: :key,
                                 location_type: :field,
                                 message: "Please select an key before you submit",
                                 reason: :blank
                               }
                             ] }
                       })
            end
          end
        end

        context "Render with errors of the association" do
          let!(:record) { Man.new(name: 'Dang Nguyen', wives_attributes: [{ age: 18}]) }

          it 'render correct error contents' do
            record.save
            response = GoogleJsonResponse.render_error(record.errors, code: 96)
            expect(response)
              .to eq({ error:
                         { code: 96,
                           errors: [
                             {
                               location: "wives.name",
                               location_type: :field,
                               message: "can't be blank",
                               reason: :blank
                             }
                           ] }
                     })
          end
        end
      end

      context "multiple error contexts" do
        before { require 'google_json_response/active_records' }
        before do
          error.add(:email, 'error')
          error.add(:name, 'error')
        end

        it 'calls ParseErrors with correct params' do
          response = GoogleJsonResponse.render_error(error)
          expect(response).to eq({ error: { errors: [
            { location: :key, location_type: :field, message: "Please select an key before you submit", reason: :blank },
            { location: :email, location_type: :field, message: "error", reason: "error" },
            { location: :name, location_type: :field, message: "error", reason: "error" }
          ] } })
        end
      end
    end
  end

  describe "Render Generic Errors" do
    context "Render errors with array of hash" do
      it 'renders error correctly' do
        response = GoogleJsonResponse.render_error([{code: 'key', message: 'message'}])
        expect(response)
          .to eq({ error: { errors: [{ reason: 'key', message: "message" }] } })
      end
    end

    context "Render errors with a hash" do
      it 'renders error correctly' do
        response = GoogleJsonResponse.render_error({code: 'key', message: 'message'})
        expect(response)
          .to eq({ error: { errors: [{ reason: 'key', message: "message" }] } })
      end
    end

    context "String Type Errors" do
      it 'renders a single string error correctly' do
        response = GoogleJsonResponse.render_error("You can't access this page", code: 'CustomCode')
        expect(response)
          .to eq({ error: { code: 'CustomCode', errors: [{ message: "You can't access this page" }] } })
      end

      context 'data is an array of Strings' do
        let(:string_array) { ['Error 1', 'Error 2'] }

        it 'renders correctly' do
          expect(GoogleJsonResponse.render_error(string_array, code: 69))
            .to eq({ error: { code: 69, errors: [{ message: 'Error 1'}, { message: 'Error 2' }] } })
        end
      end
    end

    context "Hash Type Error" do
      let(:complied_hash) { { message: 'Error' } }
      let(:not_complied_hash) { { random_key: 'Error' } }

      it 'renders hash error correctly' do
        expect(GoogleJsonResponse.render_error(complied_hash))
          .to eq({ error: { errors: [{ message: 'Error' }] } })
        expect(GoogleJsonResponse.render_error(not_complied_hash))
          .to eq({ error: { errors: [{ message: 'Unknown Error!' }] } })
      end

      context 'data is an array of hash' do
        let(:hash_array) { [complied_hash, not_complied_hash] }

        it 'renders correctly' do
          expect(GoogleJsonResponse.render_error(hash_array))
            .to eq({ error: { errors: [{ message: 'Error'}, { message: 'Unknown Error!' }] } })
        end
      end
    end

    context 'Generic Object Type Error' do
      let(:complied_object) { OpenStruct.new(message: 'Error') }
      let(:not_complied_object) { OpenStruct.new(random_attribute: 'Error') }

      it 'renders correctly' do
        expect(GoogleJsonResponse.render_error(complied_object))
          .to eq({ error: { errors: [{ message: 'Error' }] } })
        expect(GoogleJsonResponse.render_error(not_complied_object))
          .to eq({ error: { errors: [{ message: 'Unknown Error!' }] } })
      end

      context 'data is an array of generic object type' do
        let(:objects_array) { [complied_object, not_complied_object] }

        it 'renders correctly' do
          expect(GoogleJsonResponse.render_error(objects_array))
            .to eq({ error: { errors: [{ message: 'Error'}, { message: 'Unknown Error!' }] } })
        end
      end
    end
  end

  describe "Render Errors with mixed types" do
    before { require 'google_json_response/active_records' }
    let!(:record) { User.new(key: nil, name: "test") }

    before do
      record.save
    end

    let!(:error_1) { StandardError.new("Error") }
    let!(:error_2) { record.errors }
    let!(:error_3) { "Hello world" }


    it 'renders correctly' do
      response = GoogleJsonResponse.render_error([error_1, error_2, error_3], code: 66)
      expect(response)
        .to eq({ error:
                   { code: 66,
                     errors: [
                       {
                         message: "Error",
                         reason: "StandardError"
                       },
                       {
                         location: :key,
                         location_type: :field,
                         message: "Please select an key before you submit",
                         reason: :blank
                       },
                       {
                         message: "Hello world",
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
