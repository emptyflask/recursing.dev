#!/usr/bin/env ruby
# Writes resume.md from resume.tex in the emptyflask/resume flake, the same
# source the deploy builds assets/resume.pdf from. resume.md is gitignored.
#
#   ruby scripts/resume2md.rb [flake-ref]   # default github:emptyflask/resume
#
# Understands only the macros resume.tex defines (\section, \wide, \skill,
# \job) plus itemize, \href, and a few text escapes.

require "json"
require "strscan"

ROOT = File.expand_path("..", __dir__)
REF = ARGV[0] || "github:emptyflask/resume"

FRONT_MATTER = <<~MD
  ---
  layout: default
  title: Resume
  permalink: /resume/
  ---

  <div class="bbs-panel mb-8 flex items-center justify-between flex-wrap gap-4">
    <h1 class="font-mono text-2xl text-orange m-0">Jon Roberts<span class="blink-cursor"></span></h1>
    <a href="{{ '/assets/resume.pdf' | relative_url }}" class="font-mono text-aqua hover:text-orange border border-gray px-3 py-1">Download PDF</a>
  </div>
MD

# Read one {balanced} argument at the scanner's position.
def arg(s)
  s.skip(/\s*/)
  s.scan(/\{/) or raise "expected { at #{s.pos}"
  depth, out = 1, +""
  until depth.zero?
    c = s.getch or raise "unbalanced braces"
    if c == "\\"
      out << c << s.getch
      next
    end
    depth += 1 if c == "{"
    depth -= 1 if c == "}"
    out << c unless depth.zero?
  end
  out
end

def args(s, n) = Array.new(n) { arg(s) }

def inline(tex)
  s = StringScanner.new(tex)
  out = +""
  until s.eos?
    if s.scan(/\\href/)
      url, text = args(s, 2)
      out << "[#{inline(text)}](#{url})"
    elsif s.scan(/\\textbf/) then out << "**#{inline(arg(s))}**"
    elsif s.scan(/\\(?:textit|emph)/) then out << "*#{inline(arg(s))}*"
    elsif s.scan(/\\textasciitilde(\{\})?/) then out << "~"
    elsif s.scan(/\\([&%$#_{}])/) then out << s[1]
    elsif s.scan(/---/) then out << "—"
    elsif s.scan(/--/) then out << "–"
    elsif s.scan(/[{}]/) then nil
    else out << s.getch
    end
  end
  out.gsub(/\s+/, " ").strip
end

def block(tex)
  if tex =~ /\\begin\{itemize\}(.*)\\end\{itemize\}/m
    $1.split(/\\item\b/).map(&:strip).reject(&:empty?)
      .map { "- #{inline(_1)}" }.join("\n")
  else
    inline(tex)
  end
end

meta = IO.popen(["nix", "flake", "metadata", "--refresh", "--json", REF], &:read)
abort "nix flake metadata #{REF} failed" unless $?.success?
src = File.read(File.join(JSON.parse(meta).fetch("path"), "resume.tex"))
body = src[/\\begin\{document\}(.*)\\end\{document\}/m, 1]
body = body.gsub(/(?<!\\)%.*$/, "")

sections = []
s = StringScanner.new(body)
until s.eos?
  if s.scan(/\\section/)
    sections << [arg(s), []]
  elsif s.scan(/\\wide/)
    sections.last[1] << "#{block(arg(s))}\n"
  elsif s.scan(/\\skill/)
    name, value = args(s, 2)
    sections.last[1] << "#{inline(name)}\n: #{inline(value)}\n"
  elsif s.scan(/\\job/)
    dates, org, place, title, text = args(s, 5)
    entry = "### #{inline(dates)}\n\n**#{inline(title)}**  \n*#{inline(org)}*  \n#{inline(place)}\n"
    entry << "\n#{block(text)}\n" unless text.strip.empty?
    sections.last[1] << entry
  else
    s.getch
  end
end

md = +FRONT_MATTER
sections.each do |name, items|
  md << %(\n<div class="bbs-panel mb-8" markdown="1">\n\n## #{inline(name).upcase}\n)
  items.each { md << "\n" << _1 }
  md << "\n</div>\n"
end
File.write(File.join(ROOT, "resume.md"), md)
puts "Wrote resume.md from #{REF}"
