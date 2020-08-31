#!/usr/bin/env bash

## Inspired from https://github.com/tomologic/bump-semver

BUNDLE_CHANNELS_PATH=operators.operatorframework.io.bundle.channels.v1
BUNDLE_DEFAULT_CHANNEL_PATH=operators.operatorframework.io.bundle.channel.default.v1
BUNDLE_PACKAGE_PATH=operators.operatorframework.io.bundle.package.v1

bump() {
  next_ver="${PREFIX}$(increment_ver "$1")"
  latest_ver="${PREFIX}$(find_channel_semver )"


  echo "Will update ${latest_ver} to ${next_ver}"


  cd manifests || exit 7
#  echo "cp -R ${latest_ver} ${next_ver}"
#  cp -R ${latest_ver} ${next_ver}
#  cd ${next_ver}

  latest_file_name="$(find . -type f -name "*${latest_ver}*" | cut -c3-)"
  next_file_name="${latest_file_name/$latest_ver/$next_ver}"

  git mv ${latest_file_name} ${next_file_name}

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

  annotations_file=$(find_annotations_file)
  echo "Found annotations file ${annotations_file}"
#
  # channel
  channel=$(yq read ${annotations_file} "annotations[${BUNDLE_CHANNELS_PATH}]")
  echo "Read defaultChannel: ${default_channel}"

  channel_without_version="${channel%-*}-" # assumes channel ends with `-$major.$minor`
  channel_version="${channel#${channel_without_version}*}" # assumes channel ends with `-$major.$minor`

  product_version="$(grep 'version=' Dockerfile | awk -F\" '{print $2}')"

  next_channel_version="$(increment_channel ${channel_version} "0" "1")"
  next_product_version="$(increment_version ${product_version} $1)"

#  echo "Read: $channel_without_version"
#  echo "Read: $channel_version"

  # if a minor version bump (no need to do this for patch versions)
  if [[ "$1" = "minor" ]]; then

    # bump channel value
    new_channel=${channel_without_version}${next_channel_version}
    echo "Adding new channel ${new_channel} in operator annotations.yaml ..."

    # Update channel
    yq write -i ${annotations_file} "annotations[${BUNDLE_CHANNELS_PATH}]" ${new_channel}

    echo "Updating defaultChannel in operator annotations.yaml ..."
    yq write -i ${annotations_file} "annotations[${BUNDLE_DEFAULT_CHANNEL_PATH}]" ${new_channel}

    echo "Updating Dockerfile channel..."
    sed -i -e "s/LABEL ${BUNDLE_CHANNELS_PATH}.*/LABEL ${BUNDLE_CHANNELS_PATH}=${new_channel}/" Dockerfile
    sed -i -e "s/LABEL ${BUNDLE_DEFAULT_CHANNEL_PATH}.*/LABEL ${BUNDLE_DEFAULT_CHANNEL_PATH}=${new_channel}/" Dockerfile

    echo "Updating Dockerfile semver..."
    sed -i -e "s/version=\"${product_version}\"/version=\"${next_product_version}\"/" Dockerfile


  elif [[ "$1" = "patch" ]]; then

    echo "No updates in annotations.yaml needed"
    echo "No updates in Dockerfile needed"

    echo "Updating Dockerfile semver..."
    sed -i -e "s/version=\"${product_version}\"/version=\"${next_product_version}\"/" Dockerfile


  fi

  echo "DONE. Bumped: ${latest_ver} to ${next_ver}. Created ${next_file_name}. Updated "

}

find_annotations_file() {
  echo "metadata/annotations.yaml"
}

find_csv_file() {
  echo "$(find manifests -type f -name "*clusterserviceversion*")"
}

find_channel_semver() {
  annotations_file=$(find_annotations_file)
#  echo "Found annotations file ${annotations_file}"

  package_name=$(yq read ${annotations_file} "annotations[${BUNDLE_PACKAGE_PATH}]")
  package_name_length=${#package_name}
#  echo "package name length: ${package_name_length}"

  csv_file=$(find_csv_file)
#  echo "Found ClusterServiceVersion file ${csv_file}"

  current_csv=$(yq read ${csv_file} "spec.version")
#  echo "Read current_csv: ${current_csv}"

  echo "${current_csv}"

}

increment_ver() {

  sem_ver_bump "$(find_channel_semver)" "$1"
}

increment_version() {
  sem_ver_bump "$1" "$2"
}

increment_channel() {
  echo $1 | awk -F. -v a="$2" -v b="$3" \
      '{printf("%d.%d", $1+a, $2+b)}'
}

sem_ver_bump() {
case $2 in
  major) echo $1 | awk -F. -v a="1" -v b="0" -v c="0" \
        '{printf("%d.0.0", $1+a)}';;
  minor) echo $1 | awk -F. -v a="0" -v b="1" -v c="0" \
        '{printf("%d.%d.0", $1+a, $2+b)}';;
  patch) echo $1 | awk -F. -v a="0" -v b="0" -v c="1" \
        '{printf("%d.%d.%d", $1+a, $2+b , $3+c)}';;
esac

}

usage() {
  echo "Usage: bump {major|minor|patch}"
  echo "Updates ClusterServiceVersion (CSV) and metadata files, with the appropriate semantic version bumped by one."
  echo
  exit 1
}


case $1 in
  major) bump $1;;
  minor) bump $1;;
  patch) bump $1;;
  *) usage
esac