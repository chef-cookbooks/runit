provides :runit_service

# Chef::Provider::RunitService

property :resource_name, String, name_property: true

property :sv_bin, String, default: lazy { node['runit']['sv_bin'] || '/usr/bin/sv' }
property :sv_dir, [String, false], default: lazy { node['runit']['sv_dir'] || '/etc/sv' }
property :service_dir, String, default: lazy { node['runit']['service_dir'] || '/etc/service' }
property :lsb_init_dir, String, default: lazy { node['runit']['lsb_init_dir'] || '/etc/init.d' }
property :control, Array, default: []
property :options, Hash, default: {}
property :env, Hash, default: {}
property :log, [true, false], default: true
property :cookbook, String
property :check, [true, false], default: false
property :start_down, [true, false], default:false
property :delete_downfile, [true, false], default:false
property :finish, [true, false], default:false
property :supervisor_owner, String
property :supervisor_group, String
property :owner, String
property :group, String
property :enabled, [true, false], default:false
property :running, [true, false], default:false
property :default_logger = false
property :restart_on_update, [true, false], default:true
property :run_template_name = @service_name
property :log_template_name = @service_name
property :check_script_template_name = @service_name
property :finish_script_template_name = @service_name
property :control_template_names, Hash, default: {}
property :status_command = "#{@sv_bin} status #{@service_dir}"
property :sv_templates, [true, false], default: true
property :sv_timeout, Fixnum
property :sv_verbose, [true, false], default: false
property :log_dir = ::File.join('/var/log/', @service_name)
property :log_size, String
property :log_num, String
property :log_min, String
property :log_timeout, String
property :log_processor, String
property :log_socket, String
property :log_prefix, String
property :log_config_append, String



def action_class

  def sv_verbose(arg = nil)
    set_or_return(:sv_verbose, arg, kind_of: [TrueClass, FalseClass])
  end

  def service_dir(arg = nil)
    set_or_return(:service_dir, arg, kind_of: [String])
  end

  def lsb_init_dir(arg = nil)
    set_or_return(:lsb_init_dir, arg, kind_of: [String])
  end

  def control(arg = nil)
    set_or_return(:control, arg, kind_of: [Array])
  end

  def options(arg = nil)
    default_opts = @env.empty? ? @options : @options.merge(env_dir: ::File.join(@sv_dir, @service_name, 'env'))

    merged_opts = arg.respond_to?(:merge) ? default_opts.merge(arg) : default_opts

    set_or_return(
      :options,
      merged_opts,
      kind_of: [Hash],
      default: default_opts
    )
  end

  def env(arg = nil)
    set_or_return(:env, arg, kind_of: [Hash])
  end

  ## set log to current instance value if nothing is passed.
  def log(arg = @log)
    set_or_return(:log, arg, kind_of: [TrueClass, FalseClass])
  end

  def cookbook(arg = nil)
    set_or_return(:cookbook, arg, kind_of: [String])
  end

  def finish(arg = nil)
    set_or_return(:finish, arg, kind_of: [TrueClass, FalseClass])
  end

  def check(arg = nil)
    set_or_return(:check, arg, kind_of: [TrueClass, FalseClass])
  end

  def start_down(arg = nil)
    set_or_return(:start_down, arg, kind_of: [TrueClass, FalseClass])
  end

  def delete_downfile(arg = nil)
    set_or_return(:delete_downfile, arg, kind_of: [TrueClass, FalseClass])
  end

  def supervisor_owner(arg = nil)
    set_or_return(:supervisor_owner, arg, regex: [Chef::Config[:user_valid_regex]])
  end

  def supervisor_group(arg = nil)
    set_or_return(:supervisor_group, arg, regex: [Chef::Config[:group_valid_regex]])
  end

  def owner(arg = nil)
    set_or_return(:owner, arg, regex: [Chef::Config[:user_valid_regex]])
  end

  def group(arg = nil)
    set_or_return(:group, arg, regex: [Chef::Config[:group_valid_regex]])
  end

  def default_logger(arg = nil)
    set_or_return(:default_logger, arg, kind_of: [TrueClass, FalseClass])
  end

  def restart_on_update(arg = nil)
    set_or_return(:restart_on_update, arg, kind_of: [TrueClass, FalseClass])
  end

  def run_template_name(arg = nil)
    set_or_return(:run_template_name, arg, kind_of: [String])
  end
  alias template_name run_template_name

  def log_template_name(arg = nil)
    set_or_return(:log_template_name, arg, kind_of: [String])
  end

  def check_script_template_name(arg = nil)
    set_or_return(:check_script_template_name, arg, kind_of: [String])
  end

  def finish_script_template_name(arg = nil)
    set_or_return(:finish_script_template_name, arg, kind_of: [String])
  end

  def control_template_names(arg = nil)
    set_or_return(
      :control_template_names,
      arg,
      kind_of: [Hash],
      default: set_control_template_names
    )
  end

  def set_control_template_names
    @control.each do |signal|
      @control_template_names[signal] ||= @service_name
    end
    @control_template_names
  end

  def sv_templates(arg = nil)
    set_or_return(:sv_templates, arg, kind_of: [TrueClass, FalseClass])
  end

  def log_dir(arg = nil)
    set_or_return(:log_dir, arg, kind_of: [String])
  end

  def log_size(arg = nil)
    set_or_return(:log_size, arg, kind_of: [Integer])
  end

  def log_num(arg = nil)
    set_or_return(:log_num, arg, kind_of: [Integer])
  end

  def log_min(arg = nil)
    set_or_return(:log_min, arg, kind_of: [Integer])
  end

  def log_timeout(arg = nil)
    set_or_return(:log_timeout, arg, kind_of: [Integer])
  end

  def log_processor(arg = nil)
    set_or_return(:log_processor, arg, kind_of: [String])
  end

  def log_socket(arg = nil)
    set_or_return(:log_socket, arg, kind_of: [String, Hash])
  end

  def log_prefix(arg = nil)
    set_or_return(:log_prefix, arg, kind_of: [String])
  end

  def log_config_append(arg = nil)
    set_or_return(:log_config_append, arg, kind_of: [String])
  end

  def runit_attributes_from_node(run_context)
    if run_context && run_context.node && run_context.node[:runit]
      run_context.node[:runit]
    else
      {}
    end
  end
end
