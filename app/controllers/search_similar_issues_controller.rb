# loosely based on the didyoumean plugin: https://github.com/abahgat/redmine_didyoumean

class SearchSimilarIssuesController < ApplicationController
  unloadable

  def index


    stop_words = Setting.plugin_chiliproject_otrs2_chili['stop_words'].split(",")
    number_of_returned_issues = Setting.plugin_chiliproject_otrs2_chili['number_of_returned_results'].to_i

    query = params[:query] || ""
    query.strip!
    logger.info "Got request for [#{query}]"

    # extract tokens from the query
    # eg. hello "bye bye" => ["hello", "bye bye"]
    tokens = query.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect {|m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '')}
    # tokens must be at least 2 characters long
    tokens = tokens.uniq.select {|t| t.length > 1 }
    # remove stop words
    tokens = tokens.select { |t| not stop_words.include? t}
    # case insensitive search
    tokens.map! { |t| t.downcase }

    # pick the current project
    if (not params[:project_id].blank?)
      begin
        project = Project.find(params[:project_id])
        project_tree = (project.self_and_descendants.active)
      rescue ActiveRecord::RecordNotFound
        project_tree = Project.find(:all)
      end
    else
      project_tree = Project.find(:all)
    end

    # check permissions
    scope = project_tree.select {|p| User.current.allowed_to?(:view_issues, p)}
    logger.info "Set project filter to #{scope}"
    project_conditions = "project_id in (?)"
    project_variables = [scope]

    if !tokens.empty?
      sql_tokens = tokens.map {|t| '%' + t +'%'}
      one_match_conditions = " AND (" + (['LOWER(subject) like ?'] * sql_tokens.length).join(' OR ') + ")"
      one_match_variables = sql_tokens
    else
      one_match_conditions = ""
      one_match_variables = []
    end

    valid_statuses = IssueStatus.all(:conditions => ["is_closed <> ?", true])
    open_tickets_conditions = " AND status_id in (?)"
    open_tickets_variables = [valid_statuses]

    if number_of_returned_issues > 0
      # first check if there are enough open tickets with at least one match
      conditions = project_conditions + open_tickets_conditions + one_match_conditions
      variables = project_variables + open_tickets_variables + one_match_variables
      if Issue.count(:conditions => [conditions, *variables]) < number_of_returned_issues
        # now relax the match condition
        conditions = project_conditions + open_tickets_conditions
        variables = project_variables + open_tickets_variables
        if Issue.count(:conditions => [conditions, *variables]) < number_of_returned_issues
          # finally include closed tickets
          conditions = project_conditions
          variables = project_variables
        end
      end
    else
      conditions = project_conditions
      variables = project_variables
    end

    issues = Issue.find(:all, :conditions => [conditions, *variables])
    issues = (issues.sort_by {|issue| issue_ordering(issue, tokens) } )
    if number_of_returned_issues > 0
      issues = issues[0,number_of_returned_issues]
    end
    render :json => { :number => number_of_returned_issues, :issues => issues.map!{|i| i.as_json(:include => [:project, :tracker, :status, :custom_values])}}
  end

private

  # order by: open/closed -> similarity -> id
  def issue_ordering(issue, tokens)
    ordering = []
    ordering << (issue.status.is_closed ? 1 : 0)
    ordering << - tokens.count { |t| issue.subject.downcase.include? t }
    ordering << issue.id
    ordering
  end

end