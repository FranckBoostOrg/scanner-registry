project_list=$(find . -name "*.csproj")

nuget_cache=$(mktemp -d)

log.info ()
{ # $@=message
  printf "$(date +'%H:%M:%S') [\033[34m%s\033[0m] %s\n" "INFO" "${*}";
}

for project_file in $project_list
do
    project_location=$(dirname "$project_file")
    [ -f "$project_location/packages.config" ] && continue
    [ -f "$project_location/packages.lock.json" ] && continue
    [ "$(find "$project_location" -name "*.deps.json" | wc -l)" != "0" ] && continue
    [ "$(find "$project_location" -name "*Packages.props" | wc -l)" != "0" ] && continue

    log.info "Dotnet project without any lockfile. Restoring lockfile for $project_file"

    docker run --mount "type=bind,src=$project_location,dst=/tmp" \
               --mount "type=bind,src=$nuget_cache,dst=/root/.nuget" \
               --workdir /tmp \
               --entrypoint dotnet \
               mcr.microsoft.com/dotnet/sdk:9.0 restore -f --use-lock-file > /dev/null 2>&1
done