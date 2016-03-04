require 'gooddata'
require 'yaml'
require 'facets/string/interpolate'

credential = YAML.load(String.interpolate { File.read('credential.yml') })

GoodData.with_connection(credential) do |client|
  blueprint = GoodData::Model::ProjectBlueprint.build("Jira Insight #{Time.now.to_i}") do |p|
    p.add_date_dimension("resolved_date", :title => "Resolved Date")
    p.add_date_dimension("updated_date", :title => "Updated Date")
    p.add_date_dimension("created_date", :title => "Created Date")

    # Issues
    p.add_dataset("dataset.issue") do |d|
      d.add_anchor("attr.issue.id", :title => "Issue Id")
      d.add_label("label.issue.id", :reference => "attr.issue.id", :title => "Issue ID")
      d.add_label("label.issue.key", :reference => "attr.issue.id", :title => "Issue Key")

      d.add_attribute("attr.issue.summary", :title => "Issue Summary")
      d.add_label("label.issue.summary", :reference => "attr.issue.summary", :title => "Issue Summary")

      d.add_attribute("attr.issue.type", :title => "Issue Type")
      d.add_label("label.issue.type", :reference => "attr.issue.type", :title => "Issue Type")

      d.add_attribute("attr.issue.project", :title => "Project")
      d.add_label("label.issue.project", :reference => "attr.issue.project", :title => "Project")

      d.add_attribute("attr.issue.status", :title => "Issue Status")
      d.add_label("label.issue.status", :reference => "attr.issue.status", :title => "Issue Status")

      d.add_attribute("attr.issue.epic_link", :title => "Epic Link")
      d.add_label("label.issue.epic_link", :reference => "attr.issue.epic_link", :title => "Epic Link")

      d.add_reference("fact.commit.priority_weight", :dataset => "dataset.priority")

      d.add_date("resolved_date",  :dataset => "resolved_date")
      d.add_date("updated_date",  :dataset => "updated_date")
      d.add_date("created_date",  :dataset => "created_date")
    end

    # Component
    p.add_dataset("dataset.component") do |d|
      d.add_anchor("attr.component.id", :title => "Component Issue Id")
      d.add_label("label.component.id", :reference => "attr.component.id", :title => "Component issue Id")

      d.add_attribute("attr.component.name", :title => "Component Name")
      d.add_label("label.component.name", :reference => "attr.component.name", :title => "Component Name")

      d.add_reference("attr.issue.id", :dataset => "dataset.issue")
    end

    # Issue links
    p.add_dataset("dataset.issue_links") do |d|
      d.add_anchor("attr.issue_links.id", :title => "Issue Link Id")
      d.add_label("label.issue_links.id", :reference => "attr.issue_links.id", :title => "Issue Link Id")

      d.add_attribute("attr.issue_links.type", :title => "Issue Link Type")
      d.add_label("label.issue_links.type", :reference => "attr.issue_links.type", :title => "Issue Link Type")

      d.add_attribute("attr.issue_links.target_issue", :title => "Target Issue")
      d.add_label("label.issue_links.target_issue", :reference => "attr.issue_links.target_issue", :title => "Target Issue")

      d.add_reference("attr.issue.id", :dataset => "dataset.issue")
    end

    p.add_dataset("dataset.fixed_versions_of_issue") do |d|
      d.add_anchor("attr.fixed_versions_of_issue.id", :title => "Fixed Version ID")
      d.add_label("label.fixed_versions_of_issue.id", :reference => "attr.fixed_versions_of_issue.id", :title => "Fixed Version ID")

      d.add_attribute("attr.fixed_versions_of_issue.fixed_version", :title => "Fixed Version")
      d.add_label("label.fixed_versions_of_issue.fixed_version", :reference => "attr.fixed_versions_of_issue.fixed_version", :title => "Fixed Version")
      d.add_reference("attr.issue.id", :dataset => "dataset.issue")
    end

    # Priority
    p.add_dataset("dataset.priority") do |d|
      d.add_anchor("attr.priority", :title => "Priority")
      d.add_label("label.priority", :reference => "attr.priority", :title => "Priority")

      d.add_fact("fact.commit.priority_weight", :title => "Priority Weight")
    end

  end

  project = GoodData::Project.create_from_blueprint(blueprint, auth_token: credential['auth_token'])
  File.open("project_id.txt", "wb").write(project.pid)
end
