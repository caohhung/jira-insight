require 'gooddata'
require 'yaml'

project_id = File.open("project_id", "rb").read()

GoodData.with_connection do |client|
  project = GoodData.use(project_id)
  blueprint = project.blueprint

  GoodData::Model.upload_data("csv/issue.csv", blueprint, "dataset.issue")
  GoodData::Model.upload_data("csv/issue_link.csv", blueprint, "dataset.issue_links")
  GoodData::Model.upload_data("csv/component.csv", blueprint, "dataset.component")
  GoodData::Model.upload_data("csv/fixed_versions_of_issue.csv", blueprint, "dataset.fixed_versions_of_issue")
  GoodData::Model.upload_data("priority.csv", blueprint, "dataset.priority")
end
