module Youtrack
  class Client

    attr_accessor :server, :token


    def initialize( _server, _token)
      @server = _server
      @token = _token

    end

    def get_issue(issue_id)
      path = "/rest/issue/#{issue_id}"
      headers = { 'Content-Type' => 'application/json', "Accept" =>"application/json",
                  "Authorization"=> " Bearer #{token}"}

      url = server+path

      require 'rest-client'

      #response = RestClient.get(url, headers.merge({content_type: :json, accept: :json}) )
      response = RestClient.get(url, headers )


      #response = HTTParty.get(url, format: :json, pem: TOKEN, :options => { :headers => headers} )
      #puts response.body, response.code, response.message, response.headers.inspect


      #http = Net::HTTP.new($server_url)

      #request = Net::HTTP::Get.new(issue_url)
      #response = http.request(request)

      if response.code == '404'
        #puts "[Policy Violation] - Issue not found: ##{issue}"
        return nil
      end

      #data = response.body, response.code, response.message, response.headers.inspect
      #data = JSON.parse response, symbolize_names: true
      data = JSON.parse response.body, symbolize_names: true

      #puts "response:"
      #puts response.body

      data
    end


  end
end
