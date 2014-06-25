require 'podversion'

class Podversion::App < Sinatra::Base
  set :views, File.expand_path("../../../views", __FILE__)
  set :public_folder, File.expand_path("../../../public", __FILE__)

  get '/' do
    @title = "Podversion"
    slim :index
  end

  post '/version' do
    if params['domain']
      redirect to("/#{Podversion.normalize_to_domain(params['domain'])}")
    else
      redirect to("/")
    end
  end

  get '/:domain/text' do |domain|
    Podversion.new(domain).human_message true
  end

  get '/:domain' do |domain|
    version = Podversion.new(domain)
    @title = "Version of #{version.domain} - Podversion"
    @domain = version.domain
    @message = version.human_message

    slim :result
  end
end
