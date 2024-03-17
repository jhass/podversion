require "time"
require "uri"
require "faraday"

class Podversion
  PATH = "/users/sign_in"
  VERSION_HEADER = "x-diaspora-version"
  UPDATE_HEADER = "x-git-update"
  REVISION_HEADER = "x-git-revision"
  COMMIT_URL_TEMPLATE = "https://github.com/diaspora/diaspora/commit/:revision"
  TIME_FORMAT = "%Y/%m/%d %H:%M %Z"
  TIMEOUT = 5

  Faraday.default_connection.options[:timeout] = TIMEOUT

  def self.normalize_to_domain input
    input = "http://#{input}" unless input.start_with? "http"
    URI.parse(input).host
  end

  attr_reader :domain, :status, :full_version, :version, :patchlevel,
    :update, :revision

  def initialize domain
    @domain = self.class.normalize_to_domain domain

    check
  end

  def success?
    @state == :success
  end

  def commit_url
    COMMIT_URL_TEMPLATE.sub(":revision", revision)
  end

  def commit_link_tag
    "<a href='#{commit_url}'>#{commit_url}</a>"
  end

  def human_message plain_text = false
    return "Sorry, #{domain}'s SSL setup looks invalid." if @state == :bad_ssl
    return "Sorry, I couldn't connect to #{domain}." unless success?

    unless version || revision || update
      return "Either not a diaspora* pod or hasn't exposed his version"
    end

    message = ["The pod runs on #{version}."]

    if revision
      commit_link = plain_text ? commit_url : commit_link_tag
      message << "The pods current commit is #{commit_link}."
    end

    if update
      message << "The last update was around #{update.strftime(TIME_FORMAT)}."
    end

    message.join(" ")
  end

  private

  def check
    response = fetch || fetch("http")

    case response
    when nil
      @state = :failed
    when Symbol
      @state = response
    when :success?.to_proc
      @state = :success
    end

    return unless success?

    @domain = response.env[:url].host
    @status = response.status

    parse_version response[VERSION_HEADER]
    parse_update response[UPDATE_HEADER]
    parse_revision response[REVISION_HEADER]
  end

  def fetch scheme = "https", url = nil, redirect_limit = 5
    url ||= normalize_to_url(@domain, scheme)
    response = Faraday.get url
    if [301, 302].include?(response.status) && redirect_limit > 0
      return fetch scheme, response["location"], redirect_limit - 1
    end

    response
  rescue Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT, Faraday::Error::TimeoutError
    :cannot_connect
  rescue Faraday::SSLError
    :bad_ssl
  end

  def parse_version version
    @full_version = version
    @version, @patchlevel = @full_version.split "-p" if @full_version
  end

  def parse_update update
    @update = Time.parse(update).utc if update
  end

  def parse_revision revision
    if revision
      @revision = revision
      @patchlevel ||= revision[0..8]
    end
  end

  def normalize_to_url input, scheme = "https"
    input = "http://#{input}" unless input.start_with? scheme
    uri = URI.parse(input)
    uri.scheme = scheme
    uri.path = PATH
    uri.to_s
  end
end
