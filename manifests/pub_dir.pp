# @summary Manages the pub httpd directory
#
# The HTTP public direction contains files like the katello ca certificate
# for download by clients
#
# @param pub_dir_options
#   The Directory options as Apache applies them
class foreman_proxy_content::pub_dir (
  String $pub_dir_options = '+FollowSymLinks +Indexes',
) {
  #ensure_packages('katello-client-bootstrap')

  pulpcore::apache::fragment{ 'pub_dir':
    http_content  => template('foreman_proxy_content/httpd_pub.erb'),
    https_content => template('foreman_proxy_content/httpd_pub.erb'),
  }
}
