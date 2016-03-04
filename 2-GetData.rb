require 'gooddata'
require 'json'
require 'csv'
require 'time'
require 'date'
require 'yaml'
require 'jira'

jira_user = "#{ENV['JIRA_USER']}"
jira_password = "#{ENV['JIRA_SECRET']}"
jirahost = 'https://jira.intgdc.com/rest/api/2'

options = {
            :username => jira_user,
            :password => jira_password,
            :site     => jirahost,
            :context_path => '',
            :auth_type => :basic,
            :read_timeout => 120,
            :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE
          }

def new_jira_client(options)
  JIRA::Client.new(options)
end

def get_jira_project_list(jira_client)
  jira_projects = Array.new
  jira_client.Project.all.each do |project|
    jira_projects.push([project.id, project.key, project.name])
  end
  jira_projects
end


jira_client = new_jira_client(options)
issue_fields = ['id', 'key', 'issuetype', 'status', 'project', 'summary', 'key', 'customfield_12002', 'priority',
                'resolutiondate', 'updated', 'created' , 'issuelinks', 'components', 'fixVersions']

exclude_projects = []

date_format = '%m/%d/%Y'
max_results = 500
next_jql_page = true
projects = get_jira_project_list(jira_client)
FileUtils::mkdir_p 'csv'


CSV.open("csv/issue.csv", "wb") do |csv_issues|
  csv_issues << ['label.issue.id', 'label.issue.key', 'label.issue.type', 'label.issue.status', 'label.issue.project',
                 'label.issue.summary', 'label.issue.epic_link', 'dataset.priority', 'created_date', 'updated_date', 'resolved_date']
end

CSV.open("csv/issue_link.csv", "wb") do |csv_issues|
  csv_issues << ['label.issue_links.id', 'label.issue_links.type', 'dataset.issue', 'label.issue_links.target_issue']
end

CSV.open("csv/component.csv", "wb") do |csv_issues|
  csv_issues << ['label.component.id', 'label.component.name', 'dataset.issue']
end

CSV.open("csv/fixed_versions_of_issue.csv", "wb") do |csv_issues|
  csv_issues << ['label.fixed_versions_of_issue.id', 'label.fixed_versions_of_issue.fixed_version', 'dataset.issue']
end


projects.each do |project|
  next if exclude_projects.include? project[1]
  number_of_results = max_results
  start_at = 0

  while number_of_results == max_results do

    issues = jira_client.Issue.jql("project=#{project[1]}", options = {fields: issue_fields, start_at: start_at, max_results: max_results})
    next_jql_page == true ? (number_of_results = issues.size) : (number_of_results = 0)
    start_at += issues.size

    issues.each do |issue|
      p issue.key

      CSV.open("csv/issue.csv", "ab") do |csv_issues|
        resolutiondate = issue.resolutiondate.to_date.strftime(date_format) if issue.resolutiondate
        issue_priority_name = issue.priority.name if issue.priority
        csv_issues << [issue.id, issue.key, issue.issuetype.name, issue.status.name, project[1], issue.summary,
                       issue.customfield_12002, issue_priority_name, issue.created.to_date.strftime(date_format),
                       issue.updated.to_date.strftime(date_format), resolutiondate]
      end

      CSV.open("csv/issue_link.csv", "ab") do |csv_issue_link|
        issue.issuelinks.each do |issuelink|
          if not issuelink.outwardIssue
            csv_issue_link << ["#{issuelink.inwardIssue.id}-inward", issuelink.type.name, issue.id, issuelink.inwardIssue.key]
          else
            csv_issue_link << ["#{issuelink.outwardIssue.id}-outward", issuelink.type.name, issue.id, issuelink.outwardIssue.key]
          end
        end
      end

      CSV.open("csv/component.csv", "ab") do |csv_component|
        issue.components.each do |component|
          csv_component << ["#{issue.id}-#{component.id}",component.name, issue.key]
        end
      end

      CSV.open("csv/fixed_versions_of_issue.csv", "ab") do |fixed_versions_of_issue|
        issue.fixVersions.each do |fixVersion|
          fixed_versions_of_issue << ["#{issue.id}-#{fixVersion.id}", fixVersion.name, issue.id]
        end
      end
    end
  end
  sleep 3
end
