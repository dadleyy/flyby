DEFAULT_ACTIONS =
  get: method: "GET"
  create:
    method: "POST"
    has_body: true
  update:
    method: "PATCH"
    has_body: true
  destroy:
    method: "DESTROY"
    has_body: true

MEMBER_NAME_REGEX = /^(\.[a-zA-Z_$][0-9a-zA-Z_$]*)+$/

DEFAULT_HEADERS =
  "Content-Type": "application/json; charset=utf-8"
  "Accept": "application/json, text/plain, */*"

CHAR_ENCODINGS =
  "%40": "@"
  "%3A": ":"
  "%24": "$"
  "%2C": ","
  "%3B": ";"

toString = Object.prototype.toString

isSuccess = (code) ->
  code >= 200 and code < 300

isObject = (x) ->
  /object/i.test typeof x

isString = (x) ->
  /string/i.test typeof x

typeCheck = (tester) ->
  (x) -> ((toString.call x).match tester) != null

isFile = typeCheck /\[object\sfile\]/i
isBlob = typeCheck /\[object\sblob\]/i
isFormData = typeCheck /\[object\sformdata\]/i
isArray = typeCheck /\[object\sarray\]/i

toJson = (x) ->
  JSON.stringify x

isFunction = (x) ->
  /function/i.test typeof x

validDottedPath = (path) ->
    not_prop = path != "hasOwnProperty"
    dot_path = ['.', path].join ""
    is_member = MEMBER_NAME_REGEX.test dot_path
    return path && not_prop && is_member

replacementFactory = (value) ->
  (match, p1) -> "#{value}" + p1

headerGetterFactory = (str) ->
  lines = (str or "").split "\n"

  matches = (line, key) ->
    rgx = new RegExp key, "gi"
    rgx.test line

  lookup = (key) ->
    return undefined if not (typeof key).match /string/i
    result = (l for l in lines when matches l, key)[0]
    return undefined if not result or (result.split ":").length != 2
    parts = result.split ":"
    parts[1].replace /\s|\n|\r\n/g, ""

  lookup

defaultRequestTransform = (data) ->
  can_stringify = (isObject data) and not (isFile data) and not (isFormData data)
  if can_stringify then toJson data else data

defaultResponseTransform = (data, header_string) ->
  result = data

  unless (typeof data).match /string/i
    return result

  header = headerGetterFactory header_string
  content_type = header "content-type"

  if not content_type or not (content_type.match /^application\/json$/i)
    return result

  try
    result = JSON.parse data
  catch
    result = data

  result

fn =
  # fn.upper
  #
  # returns the result of the first parameter's `toUpperCase` method being called 
  # if exists, otherwise returns whatever is send it.
  upper: (x) -> x.toUpperCase?() ? x

  # fn.xhr
  #
  # returns a new xhr object
  xhr: -> new window.XMLHttpRequest()

  extend: (target, sources...) ->
    if sources.length < 1 or not (/object/i.test typeof target)
      return target

    next = sources.shift()

    for o, a of next
      target[o] = a

    if sources.length > 0
      return fn.extend.apply target, ([target].concat sources)

    target

  paramRgx: (part) ->
    new RegExp "(^|[^\\\\]):"+part+"(\\W|$)"

  lookupDotted: (data, path) ->
    return false unless validDottedPath path
    keys = path.split "."

    while keys.length and data != undefined
      k = keys.shift()
      data = if data[k] then data[k] else undefined

    data

  extractObjectMappings: (data={}, mappings={}, mapped=[]) ->
    result = {}

    search = (keys) ->
      found = undefined
      keys = keys.slice 0
      key = null

      while found == undefined and keys.length > 0
        key = keys.shift()
        continue if (key.charAt 0) != "@"
        found = fn.lookupDotted data, key.slice 1

      mapped.push key.slice 1

      found

    for m, v of mappings
      if (isArray v)
        result[m] = search v
      if (isString v) and (v.charAt 0) == "@"
        mapped.push v.slice 1
        result[m] = fn.lookupDotted data, v.slice 1
      if isFunction v
        result[m] = v data

    result

  omit: (obj, keys=[]) ->
    return obj if not (/object/i.test (typeof obj))
    result = {}

    for k, v of obj
      continue if (keys.indexOf k) >= 0
      result[k] = v

    result

  encodeUriQuery: (str) ->
    rgx_str = (Object.keys CHAR_ENCODINGS).join "|"
    replace_rgx = new RegExp rgx_str, "g"

    replace = (match) ->
      CHAR_ENCODINGS[match]

    (encodeURIComponent str).replace replace_rgx, replace


  queryString: (data) ->
    return false if not /object/i.test data
    parts = []

    serialize = (v) ->
      v

    for k, value of data
      parts.push "#{fn.encodeUriQuery k}=#{fn.encodeUriQuery serialize value}"

    if parts.length > 0 then parts.join "&" else null

  transformUrl: (url_template="", data={}) ->
    parts = url_template.split /\W/
    known_params = {}

    for p in parts
      known_params[p] = true if p and (fn.paramRgx p).test url_template

    clearFn = (match, leading_slashes, tailing) ->
      has_lead = tailing.charAt(0) == '/'

      if has_lead
        return tailing

      leading_slashes + tailing

    for pp of known_params
      param_value = if (data.hasOwnProperty pp) then data[pp] else null
      empty_rgx = new RegExp "(\/?):"+pp+"(\\W|$)", "g"
      replacement_fn = clearFn
      replacement_rgx = empty_rgx

      if param_value != null and param_value != undefined
        replacement_fn = replacementFactory param_value
        replacement_rgx = new RegExp ":"+pp+"(\\W|$)", "g"

      url_template = url_template.replace replacement_rgx, replacement_fn
      url_template = url_template.replace /\/\.(?=\w+($|\?))/, '.'

    url_template.replace /\/$/, ''


Flyby = (resource_url, url_mappings, custom_actions) ->
  actions = fn.extend {}, DEFAULT_ACTIONS, custom_actions

  class Resource
    constructor: () ->

  action = (name, action_config) ->
    action_url = action_config.url or resource_url
    action_mappings = fn.extend {}, url_mappings, action_config.params

    # check for a method defined on the custom action, otherwise revert to GET
    method = fn.upper action_config.method ? "GET"

    has_body = action_config.has_body == true
    transforms = action_config.transform or {}

    handler = (data, callback) ->
      mapping_keys = []
      mapping_data = fn.extractObjectMappings data, action_mappings, mapping_keys
      leftover = fn.omit data, mapping_keys
      query_str = fn.queryString leftover
      request_url = fn.transformUrl action_url, mapping_data
      headers = fn.extend {}, DEFAULT_HEADERS, action_config.headers
      xhr = fn.xhr()

      # if there is parameters leftover after extracting, add them
      # to the request url after the original url
      if query_str != null and not has_body
        request_url = "#{request_url}?#{query_str}"

      for key, value of headers
        value = value data if isFunction value
        xhr.setRequestHeader key, value if value != undefined

      request_method = (method? data) ? method
      xhr.open request_method, request_url, true

      loaded = ->
        status_text = xhr.statusText
        status_code = xhr.status
        response = if xhr.response then xhr.response else xhr.responseText
        headers = xhr.getAllResponseHeaders()

        result = defaultResponseTransform response, headers

        if isFunction transforms.response
          result = transforms.response response

        if isSuccess status_code
          return callback false, result, xhr

        callback {response: response}, undefined, xhr

      error =  ->
        callback {response: null}, undefined, xhr

      xhr.onload = loaded
      xhr.onerror = error

      # if the action has not specified it needs a body send it along without
      # performing any additional steps.
      return xhr.send() unless has_body

      # attempt to transform body data if the action has provided a request transform
      # callback
      body_data = (transforms.request? data) ? defaultRequestTransform data
  
      # complete the xhr by sending it with the body data
      xhr.send body_data
      true

    handler

  for a, c of actions
    Resource[a] = action a, c

  Resource

Flyby.fn = fn

if @define
  @define [], () -> return Flyby
else
  @Flyby = Flyby
