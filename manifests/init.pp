# @summary Manage containers, pods, volumes, and images with podman without a docker daemon
#
# @param podman_pkg
#   The name of the podman package (default 'podman')
#
# @param skopeo_pkg
#   The name of the skopeo package (default 'skopeo')
#
# @param buildah_pkg
#   The name of the buildah package (default 'buildah')
#
# @param buildah_pkg_ensure
#   The ensure value for the buildah package (default 'absent')
#
# @param podman_docker_pkg
#   The name of the podman-docker package (default 'podman-docker').
#
# @param podman_docker_pkg_ensure
#   The ensure value for the podman docker package (default 'installed')
#
# @param storage_options
#   A hash containing any storage options you wish to set in /etc/containers/storage.conf
#
# @param rootless_users
#   An array of users to manage using [`podman::rootless`](#podmanrootless)
#
# @param enable_api_socket
#   The enable value of the API socket (default `false`)
#
# @param pods
#   A hash of pods to manage using [`podman::pod`](#podmanpod)
#
# @param volumes
#   A hash of volumes to manage using [`podman::volume`](#podmanvolume)
#
# @param images
#   A hash of images to manage using [`podman::image`](#podmanimage)
#
# @param containers
#   A hash of containers to manage using [`podman::container`](#podmancontainer)
#
# @param manage_subuid
#   Should the module manage the `/etc/subuid` and `/etc/subgid` files (default is true)
#   The implementation uses [concat](https://forge.puppet.com/puppetlabs/concat) fragments to build
#   out the subuid/subgid entries.  If you have a large number of entries you may want to manage them
#   with another method.  You cannot use the `subuid` and `subgid` defined types unless this is `true`.
#
# @param file_header
#   Optional header when `manage_subuid` is true.  Ensure you include a leading `#`.
#   Default file_header is `# FILE MANAGED BY PUPPET`
#
# @param match_subuid_subgid
#   Enable the `subid` parameter to manage both subuid and subgid entries with the same values.
#   This setting requires `manage_subuid` to be `true` or it will have no effect.
#   (default is true)
#
# @param subid
#   A hash of users (or UIDs) with assigned subordinate user ID number and an count.
#   Implemented by using the `subuid` and `subgid` defined types with the same data.
#   Hash key `subuid` is the subordinate UID, and `count` is the number of subordinate UIDs
#
# @param nodocker
#   Should the module create the `/etc/containers/nodocker` file to quiet Docker CLI messages.
#   Values should be either 'file' or 'absent'. (default is 'absent')
#
# @example Basic usage
#   include podman
#
# @example A rootless Jenkins deployment using hiera
#   podman::subid:
#     jenkins:
#       subuid: 2000000
#       count: 65535
#   podman::volumes:
#     jenkins:
#       user: jenkins
#   podman::containers:
#     jenkins:
#       user: jenkins
#       image: 'docker.io/jenkins/jenkins:lts'
#       flags:
#         label:
#           - purpose=test
#         publish:
#           - '8080:8080'
#           - '50000:50000'
#         volume: 'jenkins:/var/jenkins_home'
#       service_flags:
#         timeout: '60'
#       require:
#         - Podman::Volume[jenkins]
#
class podman (
  String $podman_pkg,
  String $skopeo_pkg,
  Optional[String] $buildah_pkg,
  Enum['absent', 'installed'] $buildah_pkg_ensure,
  Optional[String] $podman_docker_pkg,
  Enum['absent', 'installed'] $podman_docker_pkg_ensure,
  Optional[Hash] $storage_options,
  Array $rootless_users,
  Boolean $enable_api_socket,
  Boolean $manage_subuid           = false,
  Boolean $match_subuid_subgid     = true,
  String $file_header              = '# FILE MANAGED BY PUPPET',
  Enum['absent', 'file'] $nodocker = 'absent',
  Hash $subid                      = {},
  Hash $pods                       = {},
  Hash $volumes                    = {},
  Hash $images                     = {},
  Hash $containers                 = {},
){
  include podman::install
  include podman::options
  include podman::service

  # Create resources from parameter hashes
  $pods.each |$name, $properties| { Resource['Podman::Pod'] { $name: * => $properties, } }
  $volumes.each |$name, $properties| { Resource['Podman::Volume'] { $name: * => $properties, } }
  $images.each |$name, $properties| { Resource['Podman::Image'] { $name: * => $properties, } }
  $containers.each |$name, $properties| { Resource['Podman::Container'] { $name: * => $properties, } }

  $rootless_users.each |$user| {
    unless defined(Podman::Rootless[$user]) {
      podman::rootless { $user: }
    }
  }

  Class['podman::install'] -> Class['podman::options'] -> Class['podman::service']

  User <| |> -> Podman::Rootless <| |>
}
