module Youtrack
  class Client

    attr_accessor :server, :token


    def initialize( _server, _token)
      @server = _server
      @token = _token

    end



    def request(http_method, path, data, extra_headers={})
      request_headers = build_headers(extra_headers)
      url_data = Youtrack::Client.build_http_query data

      resp = api_do_request http_method, path, data, request_headers

      #puts "response: #{resp.code}, #{resp.body}, #{resp.headers}"
      #logger.info "response: #{resp.code}, headers: #{resp.headers}"
      #if resp.code!=201 && resp.code!=200
      #  return nil
      #end

      resp_data = JSON.parse resp.body, symbolize_names: true

      resp_data
    end

    def get_projects
      #GET /rest/project/all?{verbose}

      path = "/rest/project/all"
      headers = build_headers

      url = server+path

      require 'rest-client'

      response = RestClient.get(url, headers)

      data = JSON.parse response.body, symbolize_names: true

      data
    end



    def get_issues(project_id, opts={})
      #GET /rest/issue/byproject/{project}?{filter}&{after}&{max}&{updatedAfter}&{wikifyDescription}

      s_opts = self.class.build_http_query opts
      path = "/rest/issue/byproject/#{project_id}?#{s_opts}"

      headers = build_headers

      url = server+path

      require 'rest-client'

      response = RestClient.get(url, headers)

      data = JSON.parse response.body, symbolize_names: true

      data
    end


    def get_issues_filter(project_id, filter)
      # GET /rest/issue/byproject/{project}?{filter}&{after}&{max}&{updatedAfter}&{wikifyDescription}

      f = []
      filter.each {|k ,v| f << "#{k}: #{v}"}
      s_filter = f.join(' ')

      path = "/rest/issue/byproject/#{project_id}?filter=#{s_filter}"
      headers = build_headers

      url = server+path

      require 'rest-client'

      response = RestClient.get(url, headers)

      data = JSON.parse response.body, symbolize_names: true

      data
    end

    def get_issue(issue_id)
      path = "/rest/issue/#{issue_id}"
      headers = build_headers

      url = server+path

      require 'rest-client'

      #response = RestClient.get(url, headers.merge({content_type: :json, accept: :json}) )
      response = RestClient.get(url, headers)


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


    def update_issue(issue_id, summary, desc)
      headers = build_headers

      options = {}

      ss = Rack::Utils.escape("#{summary}")
      sd = Rack::Utils.escape("#{desc}")

      resp = api_do_request :post, "/rest/issue/#{issue_id}?summary=#{ss}&description=#{sd}", {}, headers

      return false if resp.code!=200


      true
    end

    def update_issue_data(issue_id, data)
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


    def delete_issue(issue_id)
      #DELETE /rest/issue/{issue}

      headers = build_headers

      resp = api_do_request :delete, "/rest/issue/#{issue_id}", {}, headers

      true
    end



    ### helpers

    def api_do_request(method, u, data, headers={})
      #require 'http'

      u.sub!(/^\//, '')

      url = server + '/'+ u

      #headers['Content-Type'] = "application/json"
      #headers['Accept'] = "application/json"

      # do http request
      request_params = {:query=>data, :headers => headers}
      request_params[:timeout] = 5000

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
    end






    def build_headers(extra_headers={})
      headers = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          "Authorization"=> " Bearer #{token}",

      }

      headers.merge(extra_headers)
    end


    def self.build_http_query(p)
      p.map{|k,v| "#{k}=#{Rack::Utils.escape(v)}"}.join('&')
    end

  end
end
