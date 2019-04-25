require "spec_helper"
require "google_json_response/record_parsers/base"

class DummySerializer < ActiveModel::Serializer
  attributes :id, :name, :email
end

describe GoogleJsonResponse::RecordParsers::Base do
  let(:parser) { described_class.new(record, options) }
  let(:record) { OpenStruct.new(id: 1, name: 'Name', email: 'serializer@eh.com') }
  let(:options) { { serializer_klass: DummySerializer }.merge(custom_data) }

  describe '#json_options' do
    context '"only" is a symbol' do
      let(:custom_data) { { custom_data: { only: :id } } }

      it 'copies "field" option from "only" as an array' do
        expect(parser.send(:json_options)).to eq(fields: %i[id])
      end
    end

    context '"only" is an array' do
      let(:custom_data) { { custom_data: { only: %i[id email] } } }

      it 'returns "fields" option similar to input' do
        expect(parser.send(:json_options)).to eq(fields: %i[id email])
      end
    end

    context '"except" is a symbol' do
      let(:custom_data) { { custom_data: { except: :id } } }

      it 'composes attributes and relations excluding the "except"' do
        expect(parser.send(:json_options)).to eq(fields: %i[name email])
      end
    end

    context '"except" is an array' do
      let(:custom_data) { { custom_data: { except: %i[id name] } } }

      it 'composes attributes and relations excluding the "except"' do
        expect(parser.send(:json_options)).to eq(fields: %i[email])
      end
    end

    context 'both "only" and "except" are available' do
      let(:custom_data) { { custom_data: { only: :id, except: %i[id name] } } }

      it 'treats "only" higher priority' do
        expect(parser.send(:json_options)).to eq(fields: %i[id])
      end
    end

    context 'only and except options are not available' do
      let(:custom_data) { {} }

      it 'leaves fields key blank' do
        expect(parser.send(:json_options)).to eq({})
      end
    end

    context 'no serializer' do
      let(:options) { { custom_data: { only: :id } } }

      it 'leaves fields key blank' do
        expect(parser.send(:json_options)).to eq({})
      end
    end
  end
end
