require 'erb'
require 'yaml'
require 'ostruct'

tmpl, vars = ARGV

puts("template file `#{tmpl}` doesn't exist") || exit unless File.exist?(tmpl)
puts("vars file `#{vars}` doesn't exist") || exit if vars && !File.exist?(vars)

vars = OpenStruct.new(YAML.load(File.read(vars))).instance_eval { binding } if vars
tmpl = File.read(tmpl).gsub(/\$\(([A-Z_\-]+)\)/, '<%= ENV["\1"] %>')
template = ERB.new(tmpl)
rended = template.result(vars)
yamls = YAML.load_stream(rended)

def eval_yaml(h)
  return h.each { |v| eval_yaml(v) } if h.is_a?(Array)
  return unless h.is_a? Hash

  #.M***
  h.keys.select { |k| k[0..1] == ".M" } .each { |k| (h[".metadata"] ||= {})[k[2..]] = h.delete(k) }
  #.kind
  h["apiVersion"], h["kind"] = h.delete(".kind").split("::", 2) if h.key?(".kind")
  #.port
  h["port"], h["targetPort"] = h.delete(".port").split(":", 2).map(&:to_i) if h.key?(".port")
  #.env
  h["env"] = (h["env"] || []) + h.delete(".env").map { |n, v| {"name" => n, "value" => v} } if h.key?(".env")
  #.env
  if h.key?(".name")
    h["name"] = h.delete(".name")
    h["namespace"], h["name"] = h["name"].split("::") if h["name"].include?("::")
    h["labels"] ||= {}
    h["labels"]["app"] = h["name"]
  end
  #.metadata
  if h.key?(".metadata")
    h["metadata"] = h.delete(".metadata")
    keys = h.keys - ["metadata", "apiVersion", "kind"]
    h["spec"] = h.select { |k, _| keys.include?(k) }
    h.reject! { |k, _| keys.include?(k) }
  end

  h.each { |_k, v| eval_yaml(v) }
end

eval_yaml(yamls)
puts YAML.dump_stream(*yamls)
