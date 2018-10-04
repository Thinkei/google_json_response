require "spec_helper"
require 'kaminari'

describe GoogleJsonResponse::ParseActiveRecords do
  describe "#call" do
    before :each do
      User.destroy_all
    end

    context "data is a ActiveRecord::Base" do
      let!(:record_1) { User.create(key: '1', name: "test") }

      it 'returns parsed data in correct format' do
        parser = GoogleJsonResponse::ParseActiveRecords
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
        parser = GoogleJsonResponse::ParseActiveRecords
                   .new(record_relation, {
                          serializer_klass: UserSerializer,
                          include: "**",
                          api_params: {
                            sort: '+name',
                            item_per_page: 10
                          }
                        })
        parser.call
        expect(parser.parsed_data).to eq({
                                           data: {
                                             item_per_page: 10,
                                             items: [
                                               {key: "1", name: "test"},
                                               {key: "2", name: "test"},
                                               {key: "3", name: "test"}
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
        parser = GoogleJsonResponse::ParseActiveRecords
                   .new(records, {
                          serializer_klass: UserSerializer,
                          include: "**",
                          api_params: {
                            sort: '+name'
                          }
                        })
        parser.call
        expect(parser.parsed_data).to eq({
                                           data: {
                                             item_per_page: 0,
                                             items: [
                                               {key: "1", name: "test"},
                                               {key: "2", name: "test"},
                                               {key: "3", name: "test"}
                                             ],
                                             page_index: nil,
                                             sort: "+name",
                                             total_items: nil,
                                             total_pages: nil
                                           }
                                         })
      end
    end
  end
end
