
# Now we want to be able to utilize ssh public keys for authentication.
# This definition makes that happen.
# It's just a very thin wrapper around the ssh_authorized_key built-in type
# so you may not find it 100% necessary. I like having the standardized requires
# personally and may not always remember it without a definition.
define local_user::key( $key, $type ) {

  $username = $title

  ssh_authorized_key{ "${username}_${key}":
    ensure  => present,
    key     => $key,
    type    => $type,
    user    => $username,
    require => File["/home/$username/.ssh/authorized_keys"]
  }
}
