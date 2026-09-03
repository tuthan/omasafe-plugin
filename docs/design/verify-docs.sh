#!/usr/bin/env bash
set -euo pipefail

design_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
impl_dir="$(cd "$design_dir/.." && pwd)/implementation"

doc_dirs=("$design_dir")
[[ -d "$impl_dir" ]] && doc_dirs+=("$impl_dir")

jq empty "$design_dir"/fixtures/*.json

doc_paths=()
for doc_dir in "${doc_dirs[@]}"; do
  for doc_candidate in "$doc_dir"/*.md; do
    [[ -e "$doc_candidate" ]] && doc_paths+=("$doc_candidate")
  done
done

for doc_path in "${doc_paths[@]}"; do
  fence_count="$(awk '/^```/ { count++ } END { print count + 0 }' "$doc_path")"
  h1_count="$(awk '/^# / { count++ } END { print count + 0 }' "$doc_path")"
  if (( fence_count % 2 != 0 )); then
    echo "unbalanced code fences: $doc_path" >&2
    exit 1
  fi
  if (( h1_count != 1 )); then
    echo "expected one H1, found $h1_count: $doc_path" >&2
    exit 1
  fi
done

current_docs=(
  "$design_dir/README.md"
  "$design_dir/01-research-and-audit.md"
  "$design_dir/02-design-principles.md"
  "$design_dir/03-ui-overhaul-proposal.md"
  "$design_dir/04-trust-graph-spec.md"
  "$design_dir/05-implementation-roadmap.md"
)

# The per-phase task plans restate design decisions, so the same stale-phrase gate
# applies to them.
if [[ -d "$impl_dir" ]]; then
  for impl_doc in "$impl_dir"/*.md; do
    [[ -e "$impl_doc" ]] && current_docs+=("$impl_doc")
  done
fi

stale_phrases=(
  'outline `󰦟`'
  'gate on `hostWidget.cliVerified && !hostWidget.checking'
  'any `Button` gated only on `!operationRunning` stays clickable'
  'bar.shell.summon(manifest.id'
  'installed commit matches the listing'
  'installed commit differs from the listing'
  'needs catalog status listed or installed-differs'
  'follow the three grammars'
  'at most once per screen'
  'every edge dashed'
  'all edges dashed'
  'geo.lexicalOnly'
  'anchors.topMargin: flow.geometry.headerH'
  'reassigned only when `membershipKey`'
  '3792–3813'
)

for stale_phrase in "${stale_phrases[@]}"; do
  if rg -n -F "$stale_phrase" "${current_docs[@]}"; then
    echo "stale design phrase found: $stale_phrase" >&2
    exit 1
  fi
done

ruby - "${doc_dirs[@]}" <<'RUBY'
design_dir = ARGV.fetch(0)
documents = ARGV.flat_map { |dir| Dir[File.join(dir, "*.md")] }

def heading_slugs(path)
  seen = Hash.new(0)
  File.readlines(path).filter_map do |line|
    next unless line.match?(/^(#+)\s+(.+?)\s*$/)
    title = line.match(/^(#+)\s+(.+?)\s*$/)[2]
    slug = title.downcase.gsub(/[^\p{L}\p{N}\s_-]/u, "").strip.gsub(/\s/, "-")
    suffix = seen[slug]
    seen[slug] += 1
    suffix.zero? ? slug : "#{slug}-#{suffix}"
  end
end

slug_cache = {}
errors = []

documents.each do |document|
  text = File.read(document)
  text.scan(/\[[^\]]+\]\(([^)]+)\)/).flatten.each do |link|
    next if link.match?(%r{^(?:https?://|mailto:|/)})

    relative, anchor = link.split("#", 2)
    target = relative.nil? || relative.empty? ? document : File.expand_path(relative, File.dirname(document))
    unless File.exist?(target)
      errors << "missing link target: #{document}: #{link}"
      next
    end
    next if anchor.nil? || anchor.empty? || File.extname(target) != ".md"

    slug_cache[target] ||= heading_slugs(target)
    errors << "missing heading anchor: #{document}: #{link}" unless slug_cache[target].include?(anchor)
  end
end

["03-ui-overhaul-proposal.md", "04-trust-graph-spec.md"].each do |name|
  path = File.join(design_dir, name)
  language = nil
  File.foreach(path).with_index(1) do |line, number|
    if line.match?(/^```(.*)$/)
      language = language.nil? ? line.match(/^```(.*)$/)[1].strip : nil
      next
    end
    if language == "" && line.match?(/^[|+]/) && line.chomp.length > 60
      errors << "wireframe line over 60 columns: #{path}:#{number}"
    end
  end
end

abort(errors.join("\n")) unless errors.empty?
RUBY

echo "design document checks passed"
