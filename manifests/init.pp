# == Class: foreman_proxy_content
#
# Configure content for foreman proxy for use by katello
#
# === Parameters:
#
# $enable_yum::                                Enable the RPM content feature. This allows syncing, managing and serving RPM content to be consumed by package managers like yum and dnf.
#
# $enable_file::                               Enable the file content feature. This allows syncing, managing, and serving file content.
#
# $enable_docker::                             Enable the container content feature. This allows syncing, managing, and serving container content.
#
# $enable_deb::                                Enable the Debian content feature. This allows syncing, managing, and serving Debian content.
#
# $enable_ansible::                            Enable the Ansible content feature. This allows syncing, managing, and serving Ansible content.
#
# $enable_katello_agent::                      Enable katello-agent for remote yum actions
#
# $pulpcore_mirror::                           Deploy Pulp to be used as a mirror
#
# === Advanced parameters:
#
# $puppet::                                    Enable puppet
#
# $reverse_proxy::                             Add reverse proxy to the parent
#
# $reverse_proxy_port::                        Reverse proxy listening port
#
# $qpid_router_hub_addr::                      Address for dispatch router hub
#
# $qpid_router_hub_port::                      Port for dispatch router hub
#
# $qpid_router_agent_addr::                    Listener address for goferd agents
#
# $qpid_router_agent_port::                    Listener port for goferd agents
#
# $qpid_router_broker_addr::                   Address of qpidd broker to connect to
#
# $qpid_router_broker_port::                   Port of qpidd broker to connect to
#
# $qpid_router_logging_level::                 Logging level of dispatch router (e.g. info+ or debug+)
#
# $qpid_router_logging::                       Whether to log to file or syslog.
#
# $qpid_router_logging_path::                  Directory for dispatch router logs, if using file logging
#
# $qpid_router_ssl_ciphers::                   SSL Ciphers to support in dispatch router
#
# $qpid_router_ssl_protocols::                 Protocols to support in dispatch router (e.g. TLSv1.2, etc)
#
# $pulpcore_allowed_content_checksums::        List of checksums to use for pulpcore content operations
#
# $pulpcore_manage_postgresql::                Manage the Pulpcore PostgreSQL database.
#
# $pulpcore_postgresql_host::                  Host of the Pulpcore PostgreSQL database. Must be specified if external/unmanaged.
#
# $pulpcore_postgresql_port::                  Port of the Pulpcore PostgreSQL database.
#
# $pulpcore_postgresql_user::                  User of the Pulpcore PostgreSQL database.
#
# $pulpcore_postgresql_password::              Password of the Pulpcore PostgreSQL database.
#
# $pulpcore_postgresql_db_name::               Name of the Pulpcore database in PostgreSQL.
#
# $pulpcore_postgresql_ssl::                   Enable SSL connection to the Pulpcore PostgreSQL database. Only meaningful for external/unmanaged DB.
#
# $pulpcore_postgresql_ssl_require::           Configure Pulpcore to require an encrypted connection to the PostgreSQL database.
#
# $pulpcore_postgresql_ssl_cert::              Path to SSL certificate to use for Pulpcore connection to PostgreSQL database.
#
# $pulpcore_postgresql_ssl_key::               Path to key file to use for Pulpcore connection to PostgreSQL database.
#
# $pulpcore_postgresql_ssl_root_ca::           Path to the root certificate authority to validate the certificate supplied by the PostgreSQL database server.
#
# $pulpcore_worker_count::                     Number of pulpcore workers. Defaults to 8 or the number of CPU cores, whichever is smaller.
#                                              Enabling more than 8 workers, even with additional CPU cores available, likely results in performance
#                                              degradation due to I/O blocking and is not recommended in most cases. Modifying this parameter should be done
#                                              incrementally with benchmarking at each step to determine an optimal value for your deployment.
#
# $pulpcore_content_service_worker_timeout::   Gunicorn worker timeout in seconds for the pulpcore-content.service
#
# $pulpcore_api_service_worker_timeout::       Gunicorn worker timeout in seconds for the pulpcore-api.service
#
# $pulpcore_django_secret_key::                Secret key used for cryptographic operations by Pulpcore's django runtime
#
class foreman_proxy_content (
  Boolean $pulpcore_mirror = false,

  Boolean $puppet = true,

  Boolean $reverse_proxy = false,
  Stdlib::Port $reverse_proxy_port = 8443,

  Optional[String] $qpid_router_hub_addr = undef,
  Stdlib::Port $qpid_router_hub_port = 5646,
  Optional[String] $qpid_router_agent_addr = undef,
  Stdlib::Port $qpid_router_agent_port = 5647,
  String $qpid_router_broker_addr = 'localhost',
  Stdlib::Port $qpid_router_broker_port = 5671,
  String $qpid_router_logging_level = 'info+',
  Enum['file', 'syslog'] $qpid_router_logging = 'syslog',
  Stdlib::Absolutepath $qpid_router_logging_path = '/var/log/qdrouterd',
  String $qpid_router_ssl_ciphers = 'ALL:!aNULL:+HIGH:-SSLv3:!IDEA-CBC-SHA',
  Optional[Array[String]] $qpid_router_ssl_protocols = undef,

  Boolean $enable_yum = true,
  Boolean $enable_file = true,
  Boolean $enable_docker = true,
  Boolean $enable_deb = true,
  Boolean $enable_ansible = true,
  Boolean $enable_katello_agent = false,

  Boolean $pulpcore_manage_postgresql = true,
  Stdlib::Host $pulpcore_postgresql_host = 'localhost',
  Stdlib::Port $pulpcore_postgresql_port = 5432,
  Pulpcore::ChecksumTypes $pulpcore_allowed_content_checksums = $foreman_proxy_content::params::pulpcore_allowed_content_checksums,
  String $pulpcore_postgresql_user = 'pulp',
  String $pulpcore_postgresql_password = $foreman_proxy_content::params::pulpcore_postgresql_password,
  String $pulpcore_postgresql_db_name = 'pulpcore',
  Boolean $pulpcore_postgresql_ssl = false,
  Boolean $pulpcore_postgresql_ssl_require = true,
  Stdlib::Absolutepath $pulpcore_postgresql_ssl_cert = '/etc/pki/katello/certs/pulpcore-database.crt',
  Stdlib::Absolutepath $pulpcore_postgresql_ssl_key = '/etc/pki/katello/private/pulpcore-database.key',
  Stdlib::Absolutepath $pulpcore_postgresql_ssl_root_ca = '/etc/pki/tls/certs/ca-bundle.crt',
  Integer[0] $pulpcore_worker_count = $foreman_proxy_content::params::pulpcore_worker_count,
  Optional[String[50]] $pulpcore_django_secret_key = undef,
  Integer[0] $pulpcore_content_service_worker_timeout = $foreman_proxy_content::params::pulpcore_content_service_worker_timeout,
  Integer[0] $pulpcore_api_service_worker_timeout = $foreman_proxy_content::params::pulpcore_api_service_worker_timeout,
) inherits foreman_proxy_content::params {
  include certs
  include foreman_proxy

  $foreman_url = $foreman_proxy::foreman_base_url
  $foreman_host = foreman_proxy_content::host_from_url($foreman_url)
  $reverse_proxy_real = $pulpcore_mirror or $reverse_proxy

  # TODO: doesn't allow deploying a Pulp non-mirror without Foreman
  $shared_with_foreman_vhost = !$pulpcore_mirror

  $rhsm_port = $reverse_proxy_real ? {
    true  => $reverse_proxy_port,
    false => 443
  }

  #ensure_packages('katello-debug')

  include certs::foreman_proxy
  Class['certs::foreman_proxy'] ~> Service['foreman-proxy']

  class { 'foreman_proxy_content::bootstrap_rpm':
    rhsm_port => $rhsm_port,
  }

  if $reverse_proxy_real {
    class { 'foreman_proxy_content::reverse_proxy':
      url  => "${foreman_url}/",
      port => $reverse_proxy_port,
    }
  }

  include foreman_proxy_content::pub_dir

  class { 'foreman_proxy_content::dispatch_router':
    ensure        => bool2str($enable_katello_agent, 'present', 'absent'),
    agent_addr    => $qpid_router_agent_addr,
    agent_port    => $qpid_router_agent_port,
    ssl_ciphers   => $qpid_router_ssl_ciphers,
    ssl_protocols => $qpid_router_ssl_protocols,
    logging_level => $qpid_router_logging_level,
    logging       => $qpid_router_logging,
    logging_path  => $qpid_router_logging_path,
  }
  contain foreman_proxy_content::dispatch_router

  if $enable_katello_agent {
    if $pulpcore_mirror {
      class { 'foreman_proxy_content::dispatch_router::connector':
        host => $foreman_host,
        port => $qpid_router_hub_port,
      }
      contain foreman_proxy_content::dispatch_router::connector
    } else {
      class { 'foreman_proxy_content::dispatch_router::hub':
        hub_addr    => $qpid_router_hub_addr,
        hub_port    => $qpid_router_hub_port,
        broker_addr => $qpid_router_broker_addr,
        broker_port => $qpid_router_broker_port,
      }
      contain foreman_proxy_content::dispatch_router::hub
    }
  }

  if $pulpcore_mirror {
    $pulpcore_allowed_import_path    = ['/var/lib/pulp/sync_imports']
    $pulpcore_allowed_export_path    = []

    pulpcore::apache::fragment{'gpg_key_proxy':
      https_content => template('foreman_proxy_content/_pulp_gpg_proxy.erb'),
    }
  } else {
    $pulpcore_allowed_import_path    = ['/var/lib/pulp/sync_imports', '/var/lib/pulp/imports']
    $pulpcore_allowed_export_path    = ['/var/lib/pulp/exports']
  }

  if $shared_with_foreman_vhost {
    include foreman::config::apache
    $servername = $foreman::config::apache::servername
    $priority = $foreman::config::apache::priority
    $apache_http_vhost = 'foreman'
    $apache_https_vhost = 'foreman-ssl'
    $apache_https_cert = undef
    $apache_https_key = undef
    $apache_https_ca = undef
    $apache_https_chain = undef
    Class['foreman::config::apache'] -> Class['pulpcore::apache']
  } else {
    include certs::apache
    Class['certs::apache'] ~> Class['pulpcore::apache']
    $servername = $certs::apache::hostname
    $priority = undef
    $apache_http_vhost = undef
    $apache_https_vhost = undef
    $apache_https_cert = $certs::apache::apache_cert
    $apache_https_key = $certs::apache::apache_key
    $apache_https_ca = $certs::katello_default_ca_cert
    $apache_https_chain = $certs::katello_server_ca_cert
  }

  class { 'pulpcore':
    allowed_content_checksums      => $pulpcore_allowed_content_checksums,
    allowed_import_path            => $pulpcore_allowed_import_path,
    allowed_export_path            => $pulpcore_allowed_export_path,
    apache_http_vhost              => $apache_http_vhost,
    apache_https_vhost             => $apache_https_vhost,
    apache_https_cert              => $apache_https_cert,
    apache_https_key               => $apache_https_key,
    apache_https_ca                => $apache_https_ca,
    apache_https_chain             => $apache_https_chain,
    apache_vhost_priority          => $priority,
    servername                     => $servername,
    static_url                     => '/pulp/assets/',
    postgresql_manage_db           => $pulpcore_manage_postgresql,
    postgresql_db_host             => $pulpcore_postgresql_host,
    postgresql_db_port             => $pulpcore_postgresql_port,
    postgresql_db_user             => $pulpcore_postgresql_user,
    postgresql_db_password         => $pulpcore_postgresql_password,
    postgresql_db_name             => $pulpcore_postgresql_db_name,
    postgresql_db_ssl              => $pulpcore_postgresql_ssl,
    postgresql_db_ssl_require      => $pulpcore_postgresql_ssl_require,
    postgresql_db_ssl_cert         => $pulpcore_postgresql_ssl_cert,
    postgresql_db_ssl_key          => $pulpcore_postgresql_ssl_key,
    postgresql_db_ssl_root_ca      => $pulpcore_postgresql_ssl_root_ca,
    worker_count                   => $pulpcore_worker_count,
    django_secret_key              => $pulpcore_django_secret_key,
    content_service_worker_timeout => $pulpcore_content_service_worker_timeout,
    api_service_worker_timeout     => $pulpcore_api_service_worker_timeout,
    before                         => Class['foreman_proxy::plugin::pulp'],
  }

  if $enable_docker {
    include pulpcore::plugin::container
    unless $shared_with_foreman_vhost {
      include foreman_proxy_content::container
      class { 'foreman_proxy::plugin::container_gateway':
        pulp_endpoint => "https://${servername}",
      }
    }
  }
  if $enable_file {
    class { 'pulpcore::plugin::file':
      use_pulp2_content_route => true,
    }
  }
  if $enable_yum {
    class { 'pulpcore::plugin::rpm':
      use_pulp2_content_route => true,
    }
  }
  if $enable_deb {
    class { 'pulpcore::plugin::deb':
      use_pulp2_content_route => true,
    }
  }
  if $enable_ansible {
    class { 'pulpcore::plugin::ansible':
    }
  }
  include pulpcore::plugin::certguard # Required to be present by Katello when syncing a content proxy

  class { 'foreman_proxy::plugin::pulp':
    pulpcore_enabled     => true,
    pulpcore_mirror      => $pulpcore_mirror,
    pulpcore_api_url     => "https://${servername}",
    pulpcore_content_url => "https://${servername}${pulpcore::apache::content_path}",
    require              => Class['pulpcore'],
  }

  if $puppet {
    # We can't pull the certs out to the top level, because of how it gets the default
    # parameter values from the main certs class.  Kafo can't handle that case, so
    # it remains here for now.
    include puppet
    if $puppet::server and $puppet::server::foreman {
      class { 'certs::puppet':
        hostname => $certs::foreman_proxy::hostname,
        before   => Class['puppet::server::config'],
      }
    }
  }
}
