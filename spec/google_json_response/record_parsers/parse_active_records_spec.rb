require "spec_helper"
require 'kaminari'
require "google_json_response/record_parsers/parse_active_records"

describe GoogleJsonResponse::RecordParsers::ParseActiveRecords do
  describe "#call" do
    before :each do
      User.destroy_all
    end

    context "data is a ActiveRecord::Base" do
      let!(:record_1) { User.create(key: '1', name: "test") }

      it 'returns parsed data in correct format' do
        parser = GoogleJsonResponse::RecordParsers::ParseActiveRecords
                   .new(record_1, { serializer_klass: UserSerializer, include: "**" })
        parser.call
        expect(parser.parsed_data).to eq({
                                           data: {
                                             key: '1',
                                             name: 'test'
                                           }
                                         })
      end
    end

    context "data is a ActiveRecord::Relation" do
      let!(:record_1) { User.create(key: '1', name: "test") }
      let!(:record_2) { User.create(key: '2', name: "test") }
      let!(:record_3) { User.create(key: '3', name: "test") }
      let!(:record_relation) { User.where(name: 'test').page(0) }

      it 'returns parsed data in correct format' do
        parser = GoogleJsonResponse::RecordParsers::ParseActiveRecords
                   .new(record_relation, {
                     serializer_klass: UserSerializer,
                     include: "**",
                     custom_data: {
                       sort: '+name',
                       item_per_page: 10
                     }
                   })
        parser.call
        expect(parser.parsed_data).to eq({
                                           data: {
                                             item_per_page: 10,
                                             items: [
                                               { key: "1", name: "test" },
                                               { key: "2", name: "test" },
                                               { key: "3", name: "test" }
                                             ],
                                             page_index: 1,
                                             sort: "+name",
                                             total_items: 3,
                                             total_pages: 1
                                           }
                                         })
      end
    end

    context "data is an array of ActiveRecord::Base" do
      let!(:record_1) { User.create(key: '1', name: "test") }
      let!(:record_2) { User.create(key: '2', name: "test") }
      let!(:record_3) { User.create(key: '3', name: "test") }
      let!(:records) { [record_1, record_2, record_3] }

      it 'returns parsed data in correct format' do
        parser = GoogleJsonResponse::RecordParsers::ParseActiveRecords
                   .new(records, {
                     serializer_klass: UserSerializer,
                     include: "**",
                     custom_data: {
                       sort: '+name'
                     }
                   })
        parser.call
        expect(parser.parsed_data).to eq({
                                           data: {
                                             item_per_page: nil,
                                             items: [
                                               { key: "1", name: "test" },
                                               { key: "2", name: "test" },
                                               { key: "3", name: "test" }
                                             ],
                                             page_index: nil,
                                             sort: "+name",
                                             total_items: nil,
                                             total_pages: nil
                                           }
                                         })
      end
    end

    context 'input contains custom_data fields' do
      let!(:record) { User.create(key: '1', name: "test") }
      let!(:options) {
        {
          serializer_klass: UserSerializer,
          custom_data: {
            field_1: 'Field 1',
            field_2: 'Field 2'
          }
        }
      }
      let(:result) {
        {
          data: {
            field_1: "Field 1",
            field_2: "Field 2",
            item_per_page: nil,
            items: [
              { key: "1", name: "test" }
            ],
            page_index: nil,
            sort: nil,
            total_items: nil,
            total_pages: nil
          }
        }
      }
      let(:parser) { described_class.new([record], options) }

      it 'returns parsed data and custom data' do
        parser.call
        expect(parser.parsed_data).to eq result
      end
    end
  end
end
