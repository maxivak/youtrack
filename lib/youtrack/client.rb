module Youtrack
  class Client

    attr_accessor :server, :token


    def initialize( _server, _token)
      @server = _server
      @token = _token

    end

    def get_issue(issue_id)
      path = "/rest/issue/#{issue_id}"
      headers = build_headers

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

    def check_issue(issue)
      http = Net::HTTP.new($server_url)
      issue_url = "/rest/issue/#{issue}"
      request = Net::HTTP::Get.new(issue_url)
      response = http.request(request)

      if response.code == '404'
        puts "[Policy Violation] - Issue not found: ##{issue}"
        invalid_commit
      end

      validate_issue_approved(response.body, issue) if response.code == '200'
    end


    def create_issue(data)
      options = {}

      # request
      headers = build_headers
      url_data = Youtrack::Client.build_http_query data

      resp = api_do_request :put, "/rest/issue?#{url_data}", data, headers

      #logger.info "response: #{resp.code}, headers: #{resp.headers}"
      if resp.code!=201
        return nil
      end

      u_issue = resp.headers['location']

      issue_id = u_issue.scan(/http.*\/rest\/issue\/(.*?)$/).last.first

      issue_id
    end


    def update_issue(issue_id, data)
      headers = build_headers

      options = {}

      data.each do |name, v|
        url_data = Rack::Utils.escape("#{name} #{v}")

        resp = api_do_request :post, "/rest/issue/#{issue_id}/execute?command=#{url_data}", {}, headers

        # TODO: check response code
        #puts "resp code: #{resp.code}"
      end

      true
    end


    def issue_add_photo(issue_id, name, filename)
      #
      filenames = [filename]

      files = {}
      filenames.each do |f|
        files[f] = File.new(f, 'rb')
      end

      require 'rest-client'

      #
      data = {}
      data["name"] = name

      url_data = Youtrack::Client.build_http_query data

      headers = build_headers

      #headers = {content_type: :json,accept: :json}
      #headers['Content-Type'] = "application/json"
      #headers['Accept'] = "application/json"

      url = server+"/rest/issue/#{issue_id}/attachment?#{url_data}"


      #resp = RestClient.post url, data.to_json, headers
      resp = RestClient.post url, files, headers


      if resp.code!=201
        return false
      end

      #puts "resp code: #{resp.code}"
      #puts "headers: #{resp.headers.inspect}"


      true
    end


    ### helpers

    def api_do_request(method, u, data, headers={})
      #require 'http'

      u.sub!(/^\//, '')

      url = server + '/'+ u

      headers['Content-Type'] = "application/json"
      headers['Accept'] = "application/json"

      # do http request
      request_params = {:query=>data, :headers => headers}
      request_params[:timeout] = 500

      if method==:post
        response = HTTParty.post(url, request_params)
      elsif method==:get
        response = HTTParty.get(url, request_params)
      elsif method==:put
        response = HTTParty.put(url, request_params)
      elsif method==:delete
        response = HTTParty.delete(url, request_params)
      end

      #unless [200, 201].include? response.code
      #  raise 'Error API request'
      #end


      return response
      #return resp_data
    end






    def build_headers
      headers = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          "Authorization"=> " Bearer #{token}",

      }

      headers
    end


    def self.build_http_query(p)
      p.map{|k,v| "#{k}=#{v}"}.join('&')
    end

  end
end
