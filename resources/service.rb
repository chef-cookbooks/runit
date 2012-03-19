#
# Cookbook Name:: runit
# Provider:: service
#
# Copyright 2011, Joshua Timberman
# Copyright 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

actions :start, :stop, :enable, :disable, :restart, :reload, :once, :hup, :cont, :term, :kill

attribute :service_name, :name_attribute => true
attribute :directory, :kind_of => String, :required => true
attribute :control,   :default => [], :kind_of => Array
attribute :options,   :default => {}, :kind_of => Hash
attribute :variables, :kind_of => Hash, :default => :options
attribute :env,       :default => {}, :kind_of => Hash
attribute :log,       :kind_of => [TrueClass, FalseClass]
attribute :cookbook,  :kind_of => String
attribute :template,  :kind_of => [String, FalseClass], :default => :service_name
attribute :finish,    :kind_of => [TrueClass, FalseClass]
attribute :owner,     :regex => Chef::Config[:user_valid_regex]
attribute :group,     :regex => Chef::Config[:group_valid_regex]
attribute :enabled,   :default => false
attribute :running,   :default => false
