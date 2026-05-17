#!/usr/bin/env ruby

require "json"
require "optparse"

VERSION_RE = /VERSION\s*=\s*"([^"]+)"/

create_branch = false
bump_kind = :patch

OptionParser.new do |opts|
  opts.banner = "Usage: bin/bump.rb [--minor|--major] [-b|--branch]"
  opts.on("--minor", "Bump minor version") { bump_kind = :minor }
  opts.on("--major", "Bump major version") { bump_kind = :major }
  opts.on("-b", "--branch", "Create a new branch before committing") { create_branch = true }
end.parse!

Dir.chdir(File.expand_path("..", __dir__)) do
  info = JSON.parse(`gh repo view --json nameWithOwner,defaultBranchRef`)
  repo = info.fetch("nameWithOwner")
  default_branch = info.fetch("defaultBranchRef").fetch("name")

  version_file = Dir.glob("lib/**/version.rb").first or abort "version.rb not found"
  content = File.read(version_file)
  current = content[VERSION_RE, 1] or abort "VERSION not found"

  maj, min, pat = current.split(".").map(&:to_i)
  nextver = case bump_kind
    when :patch then "#{maj}.#{min}.#{pat + 1}"
    when :minor then "#{maj}.#{min + 1}.0"
    when :major then "#{maj + 1}.0.0"
    end

  abort "must be on #{default_branch}" unless `git rev-parse --abbrev-ref HEAD`.strip == default_branch
  abort "working tree not clean" unless `git status --porcelain`.empty?

  branch = default_branch
  if create_branch
    prev_tag = `gh api repos/#{repo}/tags --jq '.[0].name'`.strip
    abort "no previous tag found" if prev_tag.empty?
    branch = "release-from-#{prev_tag}"
    system("git switch -c #{branch}", exception: true)
  end

  File.write(version_file, content.sub(VERSION_RE, %(VERSION = "#{nextver}")))
  system("bundle install", exception: true)
  system("git add -u", exception: true)
  system("git commit -m 'Bump version to v#{nextver}'", exception: true)

  puts "Bumped to v#{nextver} (on #{branch})."
end
