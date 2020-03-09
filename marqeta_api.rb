require 'net/http'
require 'uri'
require 'json'

module Marqeta_APIS
  BASE_URL = 'https://sandbox-api.marqeta.com/v3/'
  APP_TOKEN = ENV['marqeta_username']    # TODO: Remove hard coded key from code
  MASTER_TOKEN = ENV['marqeta_password'] # TODO: Remove hard coded key from code

  # Load API data from external JSON files
  API_MAP = {}
  Dir['./marqeta_api_data/*.json'].each { |file| $log.info("Loading API DATA from: #{file}"); API_MAP.merge!(JSON.parse(File.read(file)))}
  
  class API
    # Make API call using POST
    #
    # @param method [String] the name of the API endpoint as defined in the external JSON files
    # @param options [Hash] a collection of all the name/value pairs used in the post body, query parameters,
    #                       or token replacements
    # @return [HTTPResponse] The response from the API call
    #
    def self.post(method, options = {})
      action = API_MAP[method]['action']
      endpoint = API_MAP[method]['endpoint']

      options[:tokens].each {|k,v| endpoint.gsub!("%#{k.to_s.upcase}%", v)} if options[:tokens]
      uri = URI.parse(BASE_URL + endpoint)
      uri.query = URI.encode_www_form(options[:query_params]) if options[:query_params]
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = 'application/json'
      request.basic_auth(APP_TOKEN, MASTER_TOKEN)
      request.body = options[:fields].to_json if options[:fields]
      
      http.request(request) 
    end
    
    # Make API call using GET
    #
    # @param method [String] the name of the API endpoint as defined in the external JSON files
    # @param options [Hash] a collection of all the name/value pairs used in the post body, query parameters,
    #                       or token replacements
    # @return [HTTPResponse] The response from the API call
    #
    def self.get(method, options = {})
      action = API_MAP[method]['action']
      endpoint = API_MAP[method]['endpoint']

      options[:tokens].each {|k,v| endpoint.gsub!("%#{k.to_s.upcase}%", v)} if options[:tokens]
      uri = URI.parse(BASE_URL + endpoint)
      uri.query = URI.encode_www_form(options[:query_params]) if options[:query_params]
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')

      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(APP_TOKEN, MASTER_TOKEN)
      
      http.request(request) 
    end
 
    # Make API call
    #
    # @param api [String] the name of the API endpoint as defined in the external JSON files
    # @param options [Hash] a collection of all the name/value pairs used in the post body, query parameters,
    #                       or token replacements
    # @return [HTTPResponse] The response from the API call
    #
    def self.make_api_call(method, options)
      action = API_MAP[method]['action']
      
      # Unpack body fields from options
      fields = {}
      API_MAP[method]['fields'].each do |field|
        fields[field.to_sym] = options[field.to_sym] if options[field.to_sym]
      end if API_MAP[method]['fields']
      
      # Unpack URL Query Parameters from options
      query_params = {}
      API_MAP[method]['query_params'].each do |param|
        query_params[param.to_sym] = options[param.to_sym] if options[param.to_sym]
      end if API_MAP[method]['query_params']
      
      # Unpack replaceable tokens from options
      tokens = {}
      API_MAP['list_cards_for_user']['tokens'].each do |token|
        tokens[token.to_sym] = options[token.to_sym] if options[token.to_sym]
      end if API_MAP[method]['tokens']
      
      # Create & Execute request
      response = case action
        when 'post'
          post(method, {:fields => fields, :query_params => query_params, :tokens => tokens})
        when 'get'
          get(method, {:fields => fields, :query_params => query_params, :tokens => tokens})
        when 'put'
          # Placeholder
      end
        
      # Handle response
      $log.debug(response.body)
      response
    end
  end
  
  class CardProducts < API
    def self.create_card_product(options = {})
      make_api_call('create_card_product', options)
    end
  end    
  
  class Cards < API
    def self.create_card(options = {})
      make_api_call('create_card', options)
    end
    
    def self.list_cards_for_user(options = {})
      make_api_call('list_cards_for_user', options)    
    end
  end    

  class FundingSources < API
    def self.create_funding_source(options = {})
      make_api_call('create_funding_source', options)
    end
  end    
  
  class GpaOrder < API
    def self.create_gpa_order(options = {})
      make_api_call('create_gpa_order', options)
    end
  end    
  
  class Simulate < API
    def self.simulate_authorization(options = {})
      make_api_call('simulate_authorization', options)  
    end
    
    def self.simulate_financial(options = {})
      make_api_call('simulate_financial', options)      
    end
  end   

  class Transactions < API
    def self.list_transactions(options = {})
      make_api_call('list_transactions', options)      
    end
  end    

  class Users < API
    def self.create_user(options = {})
      make_api_call('create_user', options)   
    end
  end      
end