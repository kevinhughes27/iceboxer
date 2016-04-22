require 'octokit'
require 'active_support/all'

module Iceboxer
  class Icebox

    def initialize(repo)
      @repo = repo
    end

    def perform
      closers.each do |closer|
        issues = Octokit.search_issues(closer[:search])
        puts "Found #{issues.items.count} issues to close in #{@repo} ..."
        issues.items.each do |issue|
          unless already_iceboxed?(issue.number)
            puts "Closing #{@repo}/issues/#{issue.number}: #{issue.title}"
            icebox(issue.number, closer)
          end
        end
      end
    end

    def closers
      [
        {
          :search => "repo:#{@repo} is:open",
          :message => "I am closing this as it is stale."
        }
      ]
    end

    def already_iceboxed?(issue)
      comments = Octokit.issue_comments(@repo, issue)
      comments.any? { |c| c.body =~ /Icebox/ }
    end

    def icebox(issue, reason)
      Octokit.add_labels_to_an_issue(@repo, issue, ["Icebox"])
      Octokit.add_comment(@repo, issue, message(reason))
      Octokit.close_issue(@repo, issue)

      puts "Iceboxed #{@repo}/issues/#{issue}!"
    end

    def message(reason)
      <<-MSG.strip_heredoc
      ![picture of the iceboxer](https://cloud.githubusercontent.com/assets/699550/5107249/0585a470-6fce-11e4-8190-4413c730e8d8.png)

      #{reason[:message]}

      I have applied the tag 'Icebox' so you can still see it by querying closed issues.

      Feel free to reopen if it is high priority and should be addressed in the next month.

      MSG
    end
  end
end
