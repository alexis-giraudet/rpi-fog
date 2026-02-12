#!/bin/sh

set -x

# Grow root partition and filesystem
root_filesystem_source=$(findmnt --json --output source / | jq --raw-output ".filesystems[0].source")
readonly root_filesystem_source
root_blockdevice_pkname=$(lsblk --json --output pkname --paths "$root_filesystem_source" | jq --raw-output ".blockdevices[0].pkname")
readonly root_blockdevice_pkname
root_blockdevice_partn=$(lsblk --json --output partn "$root_filesystem_source" | jq --raw-output ".blockdevices[0].partn")
readonly root_blockdevice_partn
growpart "$root_blockdevice_pkname" "$root_blockdevice_partn"
resize2fs "$root_filesystem_source"

set -e

temp="$(mktemp --directory)"
readonly temp
mkdir --parents "$temp/tmp/" "$temp/cache/" "$temp/bin/"
trap 'rm --recursive --force -- "$temp"' EXIT

# Stub
cat << 'EOF' > "$temp/bin/download.tpl"
#!/bin/sh
readonly cachedir="$DOWNLOAD_CACHE"
for arg in "$@"
do
    filename=$(basename -- "$arg")
    if [ -f "$cachedir/$filename" ]
    then
        cp "$cachedir/$filename" .
        exit
    fi
done
"$DOWNLOAD_CMD" "$@"
EOF
DOWNLOAD_CACHE="$temp/cache/" DOWNLOAD_CMD="$(command -v wget)" envsubst '$DOWNLOAD_CACHE $DOWNLOAD_CMD' < "$temp/bin/download.tpl" > "$temp/bin/wget"
DOWNLOAD_CACHE="$temp/cache/" DOWNLOAD_CMD="$(command -v curl)" envsubst '$DOWNLOAD_CACHE $DOWNLOAD_CMD' < "$temp/bin/download.tpl" > "$temp/bin/curl"
chmod +x "$temp/bin/"*

# Extract assets
tar --directory="$temp" --strip-components=1 --extract --file /opt/fogproject-*.tar.gz
tar --directory="$temp/cache/" --strip-components=1 --extract --file /opt/fos-*.tar.gz
tar --directory="$temp/cache/" --strip-components=1 --extract --file /opt/fog-client-*.tar.gz

# Install FOG
PATH="$temp/bin/:$PATH" routeraddress=127.0.0.1 "$temp/bin/installfog.sh" --autoaccept
