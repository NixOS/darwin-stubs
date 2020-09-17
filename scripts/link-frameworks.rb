#!/usr/bin/env ruby

require 'psych'

def framework_path(install_name)
  case
  when (m = %r{/System/Library/(?:|Private)Frameworks/([^/]+).framework/(.+)}.match(install_name))
    framework_name, suffix = m.captures
    "@#{framework_name}@/Library/Frameworks/#{framework_name}.framework/#{suffix}"
  when "/usr/lib/libobjc.A.dylib"
    "@libobjc@/lib/libobjc.A.dylib"
  else
    raise "Unhandled re-export path: #{install_name}"
  end
end

def rewrite(fpath)
  changed = false

  in_stream = File.read(fpath)
  ast = Psych.parse_stream(in_stream)

  ast.grep(Psych::Nodes::Mapping).each do |node|
    node.children.each_slice(2) do |k, v|
      if k.value == 're-exports'
        changed = true
        v.children.each do |re_export|
          re_export.value = framework_path(re_export.value)
        end
      end
    end
  end

  File.write(fpath, ast.yaml) if changed
end

Dir[ARGV.first].each { |f| rewrite(f) }
