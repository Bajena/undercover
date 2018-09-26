# frozen_string_literal: true

require 'undercover'
require 'rainbow'

module Undercover
  module CLI
    # TODO: Report calls >parser< for each file instead of
    # traversing the whole project at first!

    WARNINGS_TO_S = {
      stale_coverage: Rainbow('♻️  Coverage data is older than your ' \
        'latest changes. Re-run tests to update').yellow,
      no_changes: Rainbow('✅ No reportable changes').green
    }.freeze

    WARNINGS_TO_EXITCODE = {stale_coverage: 1, no_changes: 0}.freeze

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def self.run(args)
      opts = Undercover::Options.new.parse(args)
      syntax_version(opts.syntax_version)
      report = Undercover::Report.new(changeset(opts), opts).build

      error = report.validate(opts.lcov)
      if error
        puts(WARNINGS_TO_S[error])
        return WARNINGS_TO_EXITCODE[error]
      end

      warnings = report.build_warnings
      puts Undercover::ChangesetFormatter.new(report.changeset)
      puts Undercover::Formatter.new(warnings)
      warnings.any? ? 1 : 0
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def self.syntax_version(version)
      return unless version

      Imagen.parser_version = version
    end

    def self.changeset(opts)
      git_dir = File.join(opts.path, opts.git_dir)
      Undercover::Changeset.new(git_dir, opts.compare)
    end
  end
end
