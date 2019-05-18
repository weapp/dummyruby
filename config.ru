require "pp"
require 'net/http'
require 'json'

def ok((headers, body))
  [200, headers, body]
end

def html(*body)
  [{'Content-Type' => 'text/html'}, [layout(*body)]]
end

def titleize(text)
  text.to_s.gsub(/\b('?[a-z])/) { Regexp.last_match(1).capitalize }
end

def layout(*args)
  <<~HTML
    <!DOCTYPE html>
    <html>
      <body>
        <style>
          body { color:#333; }
          h1, h3, div {font-size: 100%; font-family: Helvetica, Arial, sans-serif; padding: 0; margin: 1em 0 .5em;}
          hr {border: 1px solid #000;}
          .display {margin:1ex;padding:1em;border:1px solid #AAA;background:#EEE;border-radius:3px;position: relative;}
          .display-error { background: #FCC; color: #A33; border-color: #A33; }
          .display-hash { background: #FEC; color: #A63; border-color: #A63; }
          .display-list { background: #CEE; color: #366; border-color: #366; }
          .display-str { background: #EFC; color: #6A3; border-color: #6A3; }
          .display-nil { background: #CCF; color: #33A; border-color: #33A; }
          .display-symbol { background: #ECF; color: #63A; border-color: #63A; }
          .display-numeric { background: #FFC; color: #AA3; border-color: #AA3; }
          pre{margin: 0; padding:0; word-wrap: break-word; white-space: pre-wrap;}
          .type { float: right; font-variant: small-caps; margin: -1em -.5em}
          /*pre {margin:1em;padding:1em;border:1px solid #AAA;overflow:auto;background:#EEE;border-radius:3px;}*/
        </style>
        <div style="margin:auto;max-width:50em;padding:1em;">
          <h1 style="">Welcome to #{titleize(__dir__.split('/').last.gsub("_", " "))}</h1>
          <div>
            #{args.join("\n")}
          </div>
        </div>
      </body>
    </html>
  HTML
end

def yaml_or_json(content)
  yaml = content.to_yaml
  yaml.length < 90 ? content.to_json : yaml
end

def inline_pp(content)
  return {type: :str, value: content.to_str} if content.respond_to?(:to_str)
  return {type: :list, value: yaml_or_json(content.to_ary)} if content.respond_to?(:to_ary)
  return {type: :hash, value: content.to_hash.to_yaml} if content.respond_to?(:to_hash)
  return {type: :nil, value: "nil"} if content.nil?
  return {type: :symbol, value: content.inspect} if content.is_a? Symbol
  return {type: :numeric, value: content.inspect} if content.is_a? Numeric
  io = StringIO.new
  PP.pp(content, io)
  io.rewind
  {type: :object, value: io.read}
end

def d(title)
  content =
    begin
      inline_pp(yield)
    rescue => e
      inline_pp(e).merge(type: :error)
    end

  %(
    <h3>#{titleize(title.to_s.gsub(/_/, " "))}</h3>
    <div class="display display-#{content[:type]}">
    <div class="type">#{content[:type]}</div>
    <pre>#{Rack::Utils.escape_html(content[:value])}</pre>
    </div>
  )
end

def credentials(env)
  auth = Rack::Auth::Basic::Request.new(env)
  auth.provided? && auth.basic? && auth.credentials || nil
end

run -> env {
  ok(
    html(
      d(:basic_auth) { credentials(env) },
      d(:rack_version) { env["rack.version"] },
      d(:rack_environment) { ENV["RACK_ENV"] },
      d(:pid) { Process.pid },
      d(:hostname) { Socket.gethostname },
      d(:ruby_platform) { RUBY_PLATFORM },
      d(:IP) { JSON[Net::HTTP.get(URI('http://httpbin.org/ip'))]["origin"].split(", ") },
      d(:PATH) { ENV["PATH"].split(":") },
      d(:ENV) { ENV.reject { |k,v| k =~ /^(BUNDLE|RUBY|PATH|RACK_ENV|HOSTNAME$)/ } },
      d(:ENV_BUNDLE) { ENV.select { |k,v| k =~ /^BUNDLE/ } },
      d(:ENV_RUBY) { ENV.select { |k,v| k =~ /^RUBY/ } },
      d(:env_headers) { env.select { |k,v| k =~ /^HTTP_/ } },
      d(:env_rack) { env.select { |k,v| k =~ /^rack\./ } },
      d(:env_server) { env.select { |k,v| k =~ /^SERVER_/ } },
      d(:env_request) { env.reject { |k,v| k =~ /^(HTTP_|SERVER_|rack\.)/ } },
      d(:TAGNAME) { File.read("TAGNAME") },
    )
  )
}
