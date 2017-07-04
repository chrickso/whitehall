class AddProblemSummaryAndSuggestedFixToLinkChecker < ActiveRecord::Migration
  def change
    add_column :link_checker_api_report_links, :problem_summary, :text
    add_column :link_checker_api_report_links, :suggested_fix, :text

    LinkCheckerApiReport::Link.find_each do |link|
      link.update_attributes!(problem_summary: '', suggested_fix: '')
    end

    change_column_null :link_checker_api_report_links, :suggested_fix, false
    change_column_null :link_checker_api_report_links, :problem_summary, false
  end
end
