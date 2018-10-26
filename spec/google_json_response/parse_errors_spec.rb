require "spec_helper"

describe GoogleJsonResponse::ParseErrors do
  describe "#call" do
    context "Error is a StandardError" do
      let!(:error_1) { InvalidExampleError.new("Error 1") }

      it 'returns parsed data in correct format' do
        parser = GoogleJsonResponse::ParseErrors.new(error_1, code: 200)
        parser.call
        expect(parser.parsed_data).to eq({
                                           error:{
                                                    code: '200',
                                                    errors: [
                                                      {
                                                        message: "Error 1",
                                                        reason: 'invalid'
                                                      }
                                                    ]
                                                  }
                                         })
      end
    end

    context "Error is a ActiveModel error" do
      let!(:record_1) { User.new(key: '1', name: "test") }
      let!(:errors_1) {
        ActiveModel::Errors.new(record_1)
      }
      before do
        errors_1.add(:name, :invalid, value: "test2")
      end

      it 'returns parsed data in correct format' do
        parser = GoogleJsonResponse::ParseErrors.new(errors_1, code: 200)
        parser.call
        expect(parser.parsed_data).to eq({
                                           error:{
                                                    code: '200',
                                                    errors: [
                                                      {
                                                        location: :name,
                                                        location_type: :field,
                                                        message: "Name is invalid",
                                                        reason: :invalid
                                                      }
                                                    ]
                                                  }
                                         })
      end
    end

    context "Error is an array of StandardError and ActiveModel error" do
      let!(:record_1) { User.new(key: '1', name: "test") }
      let!(:errors_1) {
        ActiveModel::Errors.new(record_1)
      }
      let!(:error_2) { StandardError.new("Error 2") }

      before do
        errors_1.add(:name, :invalid, value: "test2")
        errors_1.add(:name, :invalid, value: "test2", message: "^Email format is invalid")
        errors_1.add(:name, :invalid, value: "test2", message: "^Other custom message")
      end

      it 'returns parsed data in correct format' do
        parser = GoogleJsonResponse::ParseErrors.new([errors_1, error_2], code: 200)
        parser.call
        expect(parser.parsed_data).to eq({
                                           error:{
                                                    code: '200',
                                                    errors: [
                                                      {
                                                        location: :name,
                                                        location_type: :field,
                                                        message: "Email format is invalid",
                                                        reason: :invalid
                                                      },
                                                      {
                                                        location: :name,
                                                        location_type: :field,
                                                        message: "Other custom message",
                                                        reason: :invalid
                                                      },
                                                      {
                                                        message: "Error 2",
                                                        reason: 'StandardError'
                                                      }
                                                    ]
                                                  }
                                         })
      end
    end
  end
end
