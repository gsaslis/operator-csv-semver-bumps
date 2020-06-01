#!/usr/bin/env bash

## Inspired from https://github.com/tomologic/bump-semver

bump() {
  next_ver="${PREFIX}$(increment_ver "$1" "$2")"
  latest_ver="${PREFIX}$(find_channel_semver "$1")"

  echo "Will update ${latest_ver} to ${next_ver}"


  cd manifests || exit 7
  echo "cp -R ${latest_ver} ${next_ver}"
  cp -R ${latest_ver} ${next_ver}
  cd ${next_ver}

  latest_file_name="$(find . -type f -name "*${latest_ver}*" | cut -c3-)"
  next_file_name="${latest_file_name/$latest_ver/$next_ver}"

  mv ${latest_file_name} ${next_file_name}


  echo "Replacing .spec.version ..."

  tmp=$(mktemp)
  yq write -i ${next_file_name} spec.version ${next_ver}
#  yq ".spec.version = \"${next_ver}\"" ${next_file_name} > $tmp && mv $tmp ${next_file_name}


  echo "Replacing .metadata.name ..."

  latest_metadata_name=$( yq r ${next_file_name} metadata.name )
#  latest_metadata_name=$( yq '.metadata.name' ${next_file_name} )
  next_metadata_name="${latest_metadata_name/$latest_ver/$next_ver}"

  tmp=$(mktemp)
  yq write -i ${next_file_name} metadata.name ${next_metadata_name}
#  yq ".metadata.name = ${next_metadata_name}" ${next_file_name} > $tmp && mv $tmp ${next_file_name}


  echo "Replacing .spec.replaces ..."

  tmp=$(mktemp)
  yq write -i ${next_file_name} spec.replaces ${latest_metadata_name}
#  yq ".spec.replaces = ${latest_metadata_name}" ${next_file_name} > $tmp && mv $tmp ${next_file_name}


  cd ../

  package_file=$(find_package_file)
  echo "Found package file ${package_file}"
#
#  default_channel=$(yq read ${package_file} defaultChannel)
#
#  echo "Read defaultChannel: ${default_channel}"

  # channel
  channel=$1
  channel_version=${channel: -3} # assumes channel ends with `-$major.$minor`
  channel_without_version=${channel/${channel_version}/} # assumes channel ends with `-$major.$minor`

  # if a minor version bump (no need to do this for patch versions)
  if [[ "$2" = "minor" ]]; then

    # bump channel value
    new_channel=${channel_without_version}$(increment_channel ${channel: -3} "0" "1")
    echo "Adding new channel ${new_channel} in operator package.yaml ..."

    # add a new entry to channels
    yq write -i ${package_file} "channels.[+].name" ${new_channel}
    yq write -i ${package_file} "channels.(name==${new_channel}).currentCSV" ${next_metadata_name}

    echo "Updating defaultChannel in operator package.yaml ..."

    yq write -i ${package_file} "defaultChannel" ${new_channel}

  elif [[ "$2" = "patch" ]]; then

    echo "Updating currentCSV of defaultChannel in operator package.yaml ..."

    yq write -i ${package_file} "channels.(name==${channel}).currentCSV" ${next_metadata_name}

  fi

  echo "DONE. Bumped: ${latest_ver} to ${next_ver}. Created ${next_file_name}. Updated "

}

find_package_file() {
  find . -type f -name "*.package.yaml"
}

find_channel_semver() {
  package_file=$(find_package_file)
#  echo "Found package file ${package_file}"

  current_csv=$(yq read ${package_file} "channels.(name==$1).currentCSV")
#  echo "Read current_csv: ${current_csv}"

  package_name=$(yq read ${package_file} "packageName")
  package_name_length=${#package_name}
#  echo "package name length: ${package_name_length}"

  version_string=".v"
  version_string_length=${#version_string}
#  echo "Read version string length: ${version_string_length}"

  replacement_length=${package_name_length}+${version_string_length}
#  echo "Replacement length: ${replacement_length}"

  echo "${current_csv:${replacement_length}}"

}

increment_ver() {

  sem_ver_bump "$(find_channel_semver $1)" "$2"
}

increment_channel() {
  echo $1 | awk -F. -v a="$2" -v b="$3" \
      '{printf("%d.%d", $1+a, $2+b)}'
}

sem_ver_bump() {
case $2 in
  major) echo $1 | awk -F. -v a="1" -v b="0" -v c="0" \
        '{printf("%d.0.0", $1+a';;
  minor) echo $1 | awk -F. -v a="0" -v b="1" -v c="0" \
        '{printf("%d.%d.0", $1+a, $2+b)}';;
  patch) echo $1 | awk -F. -v a="0" -v b="0" -v c="1" \
        '{printf("%d.%d.%d", $1+a, $2+b , $3+c)}';;
esac

}

usage() {
  echo "Usage: bump {channel} {major|minor|patch}"
  echo "Creates a new folder and ClusterServiceVersion (CSV) file, with the appropriate semantic version bumped by one."
  echo
  exit 1
}


case $2 in
  major) bump $1 $2;;
  minor) bump $1 $2;;
  patch) bump $1 $2;;
  *) usage
esac