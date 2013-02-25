# This module has been created with influence from both
# https://github.com/icebourg/LC.tv-Puppet-Configuration
# and https://github.com/reidmv/puppet-module-local_user
#
define local_user (
  $name,
  $email,
  $uid,
  $gid     = $uid,
  $groups  = undef,
  $ensure  = present,
  $comment = 'User &',
  $shell   = '/bin/bash',
) {
  $username = $title

  # If the user already exists, we will not manage the password.
  # If the user doesn't exist, we will create it with a random
  # password. The custom fact local_users is used to determine 
  # whether or not the user has already been created at the time
  # of the current Puppet run.
  $user_exists = $username in split($::local_users, ',')

  # How the new random password gets set can be accomplished any
  # number of ways. This is not the only possibility.
  $password = $user_exists ? {
    true  => undef,
    false => generate(
      '/bin/sh',
      '-c',
      'tr -dc A-Za-z0-9 < /dev/urandom | head -c8'
    ),
  }

  # Create the user
  user { $username:
    ensure   => $ensure,
    home     => "/home/$username",
    comment  => "$name $email $comment",
    shell    => $shell,
    uid      => $uid,
    gid      => $gid,
    groups   => $groups,
    password => $password,
  }
  
  # Ensure we have a group by the same name / id.
  group { $username:
    gid     => $gid,
    require => User[$username]
  }

  # Make sure they have a home with proper permissions.
  # Had a problem where this would fire before a group was created,
  # so I added the group definition above to be explicit, then made this
  # require that the group exists before executing.
  file { "/home/$username/":
    ensure  => directory,
    owner   => $username,
    group   => $username,
    mode    => 750,
    require => [ User[$username], Group[$username] ]
  }

  # And a place with the right permissions for the SSH related configs
  file { "/home/$username/.ssh":
    ensure  => directory,
    owner   => $username,
    group   => $username,
    mode    => 700,
    require => File["/home/$username/"]
  }

  # Now make sure that the ssh key authorized files is around
  file { "/home/$username/.ssh/authorized_keys":
    ensure  => present,
    owner   => $username,
    group   => $username,
    mode    => 600,
    require => File["/home/$username/.ssh"]
  }

  # Do SOMETHING to notify the user of the new randomly generated
  # password. A custom function could be used to generate an email
  # message, for example. Here, we're simply creating a notify 
  # resource for the report.
  if $password {
    notify { "$title user password set":
      message => "Password for user $title on $::certname has been set to: $password",
    }
    exec { "mail ":
      path  => "/bin:/usr/bin",
      refreshonly => true,
      subscribe   => User[$username]
    }
  }
}
