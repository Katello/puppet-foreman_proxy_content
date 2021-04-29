require 'spec_helper_acceptance'

describe 'pulpcore mirror' do
  let(:pp) do
    <<~PUPPET
    #class { 'katello::repo':
    #  repo_version => 'nightly',
    #  before       => Class['foreman_proxy_content'],
    #}
    include pulpcore::repo

    if $facts['os']['release']['major'] == '7' {
      package { 'epel-release':
        ensure => present,
        before => Class['foreman_proxy_content'],
      }

      class { 'postgresql::globals':
        version              => '12',
        client_package_name  => 'rh-postgresql12-postgresql-syspaths',
        server_package_name  => 'rh-postgresql12-postgresql-server-syspaths',
        contrib_package_name => 'rh-postgresql12-postgresql-contrib-syspaths',
        service_name         => 'postgresql',
        datadir              => '/var/lib/pgsql/data',
        confdir              => '/var/lib/pgsql/data',
        bindir               => '/usr/bin',
      }
      class { 'redis::globals':
        scl => 'rh-redis5',
      }
    }

    include certs::foreman_proxy

    class { 'foreman_proxy':
      puppet              => false,
      puppetca            => false,
      puppet_group        => 'root',
      register_in_foreman => false,
      ssl_port            => 9090,
      manage_puppet_group => false,
      ssl_ca              => $certs::foreman_proxy::proxy_ca_cert,
      ssl_cert            => $certs::foreman_proxy::proxy_cert,
      ssl_key             => $certs::foreman_proxy::proxy_key,
    }

    class { 'foreman_proxy_content':
      pulpcore_mirror => true,
      require         => Class['pulpcore::repo'],
    }
    PUPPET
  end

  it_behaves_like 'a idempotent resource'

  describe service('httpd') do
    it { is_expected.to be_running }
    it { is_expected.to be_enabled }
  end

  describe file('/etc/httpd/conf.d/10-pulpcore.conf') do
    it { is_expected.to be_file }
    it { is_expected.to contain(/DOES NOT MATCH/) }
  end

  describe file('/etc/httpd/conf.d/10-pulpcore-ssl.conf') do
    it { is_expected.to be_file }
    it { is_expected.to contain(/DOES NOT MATCH/) }
  end
end
