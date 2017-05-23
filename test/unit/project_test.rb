# This file is a part of redmine_reporting,
# a reporting and statistics plugin for Redmine.
#
# Copyright (c) 2016-2017 AlphaNodes GmbH
# https://alphanodes.com
#
# redmine_reporting is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# redmine_reporting is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_reporting.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class ProjectTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issue_statuses, :issues,
           :journals, :journal_details,
           :enumerations, :users, :issue_categories,
           :projects_trackers,
           :custom_fields,
           :custom_fields_projects,
           :custom_fields_trackers,
           :custom_values,
           :roles,
           :member_roles,
           :members,
           :enabled_modules,
           :versions,
           :wikis, :wiki_pages, :wiki_contents, :wiki_content_versions,
           :groups_users,
           :time_entries,
           :news, :comments,
           :documents,
           :workflows

  def setup
    User.current = User.find(1)
  end

  def test_create_project
    Project.delete_all
    Project.create!(name: 'Project Messenger', identifier: 'project-messenger')
    assert_equal 1, Project.count
  end

  def test_load_project
    Project.find(1)
  end
end
