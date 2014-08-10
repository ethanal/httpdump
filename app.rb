require "cgi"
require "json"
require "sinatra"


def base_resp(request)
  headers = request.env.select {|key, _| key.to_s.start_with?("HTTP_")}
  headers.keys.each do |key|
    headers[key.slice(5..-1)] = headers[key]
    headers.delete(key)
  end

  args = CGI::parse(request.query_string)
  args.each do |key, value|
    if args[key].length == 1
      args[key] = args[key][0]
    end
  end

  {
    origin: request.ip,
    method: request.request_method,
    path: request.path,
    headers: headers,
    args: args
  }
end

def post_put_patch_delete(request)
  if request.POST.length == 0
    request.body.rewind
    body = request.body.read
    begin
      json = JSON.parse body
    rescue JSON::ParserError => e
      json = nil
    end
  else
    body = ""
    json = nil
  end


  resp = base_resp(request).update({
    form: request.POST.reject {|_, v| v.is_a?(Hash)},
    files: request.POST.select {|_, v| v.is_a?(Hash)}
                       .map {|_, v| v.reject{|k| k == :tempfile}},

    json: json,
    data: body
  })
  JSON.pretty_generate(resp)
end


get %r{/.*} do
  content_type :json
  resp = base_resp(request)

  JSON.pretty_generate(resp)
end

post %r{/.*} do
  content_type :json
  post_put_patch_delete(request)
end

put %r{/.*} do
  content_type :json
  post_put_patch_delete(request)
end

patch %r{/.*} do
  content_type :json
  post_put_patch_delete(request)
end

delete %r{/.*} do
  content_type :json
  post_put_patch_delete(request)
end

options %r{/.*} do
  response.headers["Allow"] = "GET, PUT, POST, PATCH, DELETE, OPTIONS"
  ""
end
