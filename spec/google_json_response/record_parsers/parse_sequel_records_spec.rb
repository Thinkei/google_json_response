require "spec_helper"
require "google_json_response/record_parsers/parse_sequel_records"

describe GoogleJsonResponse::RecordParsers::ParseSequelRecords do
  describe "#call" do
    before :each do
      Item.dataset.destroy
    end

    context "data is a ActiveRecord::Base" do
      before do
        @items = SequelDB[:items] # Create a dataset
        @items.insert(:name => 'test', code: '1')
      end
      let!(:record_1) { Item.where(name: 'test').first }

      it 'returns parsed data in correct format' do
        parser = GoogleJsonResponse::RecordParsers::ParseSequelRecords
                   .new(record_1, { serializer_klass: ItemSerializer, include: "**" })
        parser.call
        expect(parser.parsed_data).to eq({
                                           data: {
                                             code: '1',
                                             name: 'test'
                                           }
                                         })
      end
    end

    context "data is a ActiveRecord::Relation" do
      before do
        @items = SequelDB[:items] # Create a dataset
        @items.insert(:name => 'test', code: '1')
        @items.insert(:name => 'test', code: '2')
        @items.insert(:name => 'test', code: '3')
      end
      let!(:record_1) { Item.where(code: '1').first }
      let!(:record_2) { Item.where(code: '2').first }
      let!(:record_3) { Item.where(code: '3').first }
      let!(:record_relation) { Item.where(name: 'test').paginate(1, 10) }

      it 'returns parsed data in correct format' do
        parser = GoogleJsonResponse::RecordParsers::ParseSequelRecords
                   .new(record_relation, {
                          serializer_klass: ItemSerializer,
                          include: "**",
                          custom_data: {
                            sort: '+name'
                          }
                        })
        parser.call
        expect(parser.parsed_data).to eq({
                                           data: {
                                             item_per_page: 10,
                                             items: [
                                               {code: '1', name: "test"},
                                               {code: '2', name: "test"},
                                               {code: '3', name: "test"}
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
      before do
        @items = SequelDB[:items] # Create a dataset
        @items.insert(:name => 'test', code: '1')
        @items.insert(:name => 'test', code: '2')
        @items.insert(:name => 'test', code: '3')
      end
      let!(:record_1) { Item.where(code: '1').first }
      let!(:record_2) { Item.where(code: '2').first }
      let!(:record_3) { Item.where(code: '3').first }
      let!(:records) { [record_1, record_2, record_3] }

      it 'returns parsed data in correct format' do
        parser = GoogleJsonResponse::RecordParsers::ParseSequelRecords
                   .new(records, {
                          serializer_klass: ItemSerializer,
                          include: "**",
                          custom_data: {
                            sort: '+name'
                          }
                        })
        parser.call
        expect(parser.parsed_data).to eq({
                                           data: {
                                             items: [
                                               {code: '1', name: "test"},
                                               {code: '2', name: "test"},
                                               {code: '3', name: "test"}
                                             ],
                                             sort: "+name",
                                             total_items: 3,
                                           }
                                         })
      end
    end
  end
end
