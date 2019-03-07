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
      #https://www.jetbrains.com/help/youtrack/incloud/api-admin-projects.html

      path = "/admin/projects"
      headers = build_headers

      url = server+path

      require 'rest-client'

      response = RestClient.get(url, headers)

      data = JSON.parse response.body, symbolize_names: true

      data
    end



    def get_issues(project_id, opts={})
      #
      s_opts = self.class.build_http_query opts
      path = "/issues/byproject/#{project_id}?#{s_opts}"

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

    def get_issue(issue_id, return_fields=nil)
      path = "/issues/#{issue_id}"
      headers = build_headers

      #url = URI.join(server, path).to_s
      url = server+ path

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



    def create_issue(project_id, fields_data, return_fields=nil)
      # https://www.jetbrains.com/help/youtrack/incloud/api-issues.html
      options = {}

      # request
      headers = build_headers
      #url_data = Youtrack::Client.build_http_query data

      data = fields_data.dup
      data[:project] = {id: project_id}


      resp = api_do_request :post, "/issues", nil, data, headers

      if resp.code!=200
        return nil
      end

      data = JSON.parse resp.body, symbolize_names: true

      issue_id = data[:id]

      issue_id
    end


    def update_issue(issue_id, summary, desc, return_fields=nil)
      # https://www.jetbrains.com/help/youtrack/incloud/api-issues-id.html#post-issues-id

      headers = build_headers

      options = {}

      data = {
          summary: summary,
          description: desc,

      }
      #ss = Rack::Utils.escape("#{summary}")
      #sd = Rack::Utils.escape("#{desc}")

      resp = api_do_request :post, "/issues/#{issue_id}", nil, data, headers

      return false if resp.code!=200


      true
    end

    def update_issue_data(issue_id, fields)
      headers = build_headers

      fields.each do |name, v|
        #vs = Rack::Utils.escape("#{name} '#{v}'")
        vs = "#{name} #{v}"

        post_data = {
            query: vs,
            issues: [ { id: issue_id } ]
        }

        resp = api_do_request :post, "commands", nil, post_data, headers

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

    def api_do_request(method, u, query_data, data, headers={})
      #require 'http'

      u.sub!(/^\//, '')

      url = server + '/'+ u

      #headers['Content-Type'] = "application/json"
      #headers['Accept'] = "application/json"

      # do http request
      request_params = {:headers => headers}
      if query_data
        request_params[:query] = query_data
      end
      if data
        request_params[:body] = data.to_json
      end

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
