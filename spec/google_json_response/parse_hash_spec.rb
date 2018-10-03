require "spec_helper"

describe GoogleJsonResponse::ParseHash do
  describe "#call" do
    let!(:success_message) { {message: "saved successfully"} }
    it 'returns parsed data correctly' do
      parser = GoogleJsonResponse::ParseHash
                 .new(success_message)
      parser.call
      expect(parser.parsed_data).to eq({
                                         data: {
                                           message: 'saved successfully'
                                         }
                                       })
    end
  end
end
