Given(/^there is a topic with published documents that have links$/) do
  @topic = create(:topic, name: "A Topic")
  @department = create(:ministerial_department, name: "A Department")

  publication_one = create(:published_publication,
                           title: "Publication #1",
                           lead_organisations: [@department],
                           body: "[A broken page](https://www.gov.uk/another-bad-link)\n[A good link](https://www.gov.uk/another-good-link)")
  publication_two = create(:published_publication,
                           title: "Publication #2",
                           lead_organisations: [@department],
                           body: "[Good](https://www.gov.uk/good-link)\n[A good link](https://www.gov.uk/another-good-link)")

  another_bad_link = create(:link_checker_api_report_link, uri: "https://www.gov.uk/another-bad-link", status: "broken")
  create(:link_checker_api_report, batch_id: 1, link_reportable: publication_one, links: [another_bad_link])
  create(:link_checker_api_report, batch_id: 2, link_reportable: publication_two, links: [])
end

When(/^I view the documents index page$/) do
  visit admin_editions_path(organisation: @department.id)
  page.click_on "Reset all fields"
end

When(/^I filter by broken links$/) do
  page.check "Only broken links"
  page.click_on "Search"
end

Then(/^I see only documents with broken links$/) do
  assert page.has_content?("Publication #1")

  assert page.has_no_content?("Publication #2")
end
