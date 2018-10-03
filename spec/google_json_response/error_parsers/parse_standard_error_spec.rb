require "spec_helper"

describe GoogleJsonResponse::ErrorParsers::ParseStandardError do
  describe "#call" do
    context "Error is a StandardError" do
      let!(:error_1) { InvalidExampleError.new("Error 1") }

      it 'returns parsed data in correct format' do
        parser = GoogleJsonResponse::ErrorParsers::ParseStandardError.new(error_1, code: 200)
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
  end
end
