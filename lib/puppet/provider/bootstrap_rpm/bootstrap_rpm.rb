require 'fileutils'

Puppet::Type.type(:bootstrap_rpm).provide(:bootstrap_rpm) do

  commands :rpmbuild => 'rpmbuild'
  commands :rpm => 'rpm'
  commands :rpm2cpio => 'rpm2cpio'
  commands :cpio => 'cpio'

  def create
    copy_sources
    write_specfile
    build_rpm

    if rpm_changed?
      copy_rpm
      copy_srpm
      link_rpm
    end
  ensure
    FileUtils.remove_dir(base_dir) if File.directory?(base_dir)
    @base_dir = nil
  end

  def exists?
    copy_sources
    write_specfile
    build_rpm

    (!resource[:symlink] || File.exist?(resource[:symlink])) && !rpm_changed?
  end

  private

  def base_dir
    @base_dir ||= Dir.mktmpdir
  end

  def sources_dir
    mkdir('SOURCES')
  end

  def spec_dir
    mkdir('SPECS')
  end

  def rpm_dir
    mkdir('RPMS')
  end

  def srpm_dir
    mkdir('SRPMS')
  end

  def copy_sources
    FileUtils.copy(resource[:script], File.join(sources_dir, File.basename(resource[:script])))
  end

  def write_specfile
    File.open(File.join(spec_dir, "#{resource[:name]}.spec"), 'w') do |file|
      file.write(spec)
    end
  end

  def release
    if (latest = latest_rpm)
      rel = rpm('-qp', latest, "--queryformat=%{release}")
      rel.to_i + 1
    else
      1
    end
  end

  def build_rpm
    output = rpmbuild(
      '-ba',
      File.join(spec_dir, "#{resource[:name]}.spec"),
      '--define', "_topdir #{base_dir}",
      '--define', "name #{resource[:name]}",
      '--define', "release #{release}"
    )
  end

  def copy_rpm
    FileUtils.copy(built_rpm, resource[:dest])
  end

  def copy_srpm
    FileUtils.copy(built_srpm, resource[:dest])
  end

  def rpm_changed?
    changed = true
    return changed unless latest_rpm

    Dir.mktmpdir do |dir|
      srpm = latest_rpm.gsub('noarch', 'src')
      temp_srpm = File.join(dir, File.basename(srpm))
      FileUtils.copy(srpm, temp_srpm)

      Dir.chdir(dir) do
        output = rpm2cpio(temp_srpm)
        File.open('srpm.cpio', 'w') { |file| file.write(output) }
        cpio('-idmv', '--file', 'srpm.cpio')
      end

      # Prior implementation of bootstrap RPM created a tarball with
      # the source script in it. If an RPM is detected with a tarball
      # source, assume this is an upgrade and generate a new bootstrap
      # RPM to be based on the new system from this point forward.
      # This if condition can then be dropped in the next release.
      if Dir[File.join(dir, '*.tar.gz')].any?
        return true
      end

      old_spec = File.read(Dir.glob("#{dir}/*.spec")[0])
      old_source = File.read(Dir.glob("#{dir}/#{File.basename(resource[:script])}")[0])

      new_spec = spec
      new_source = File.read(resource[:script])

      digest_old_spec = Digest::SHA256.hexdigest(old_spec)
      digest_new_spec = Digest::SHA256.hexdigest(new_spec)

      digest_old_source = Digest::SHA256.hexdigest(old_source)
      digest_new_source = Digest::SHA256.hexdigest(new_source)

      changed = (digest_old_spec != digest_new_spec) || (digest_old_source != digest_new_source)
    end

    changed
  end

  def built_rpm
    Dir.glob("#{rpm_dir}/noarch/*#{release}.noarch.rpm")[0]
  end

  def built_srpm
    Dir.glob("#{srpm_dir}/*")[0]
  end

  def link_rpm
    FileUtils.ln_s(latest_rpm, resource[:symlink], force: true) if resource[:symlink]
  end

  def latest_rpm
    rpms = Dir.glob("#{resource[:dest]}/*.noarch.rpm")
    rpms = rpms.reject { |rpm| rpm.end_with?("latest.noarch.rpm") }

    return false if rpms.empty?

    rpms.max_by { |name| rpm('-qp', name, "--queryformat=%{release}") }
  end

  def mkdir(dir)
    path = File.join(base_dir, dir)
    Dir.mkdir(path) unless File.exist?(path)
    path
  end

  def spec
    <<~HEREDOC
      %global _binary_filedigest_algorithm md5
      %global _source_filedigest_algorithm md5

      Name:      %{name}
      Version:   1.0
      Release:   %{release}
      Summary:   CA certificate and post installation script that configures rhsm.

      Group:     Applications/System
      License:   GPL
      Source0:   katello-rhsm-consumer
      BuildArch: noarch

      Requires:  subscription-manager

      %description
      CA certificate and post installation script that configures rhsm.

      %prep

      %build

      %install
      rm -rf %{buildroot}

      install -Dp -m0755 %{SOURCE0} %{buildroot}%{_bindir}/katello-rhsm-consumer

      %clean
      rm -rf %{buildroot}

      %post
      %{_bindir}/katello-rhsm-consumer

      %postun
      if [ $1 -eq 0 ]; then
        test -f /etc/rhsm/rhsm.conf.kat-backup && command cp /etc/rhsm/rhsm.conf.kat-backup /etc/rhsm/rhsm.conf
      fi

      %files
      %attr(755,-,-) %{_bindir}/katello-rhsm-consumer
    HEREDOC
  end
end
