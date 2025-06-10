#!/bin/bash

STD_IN="$(</dev/stdin)"

read -r -d '' VAR << EOM
.runs[0].components += [
        {
          "purl": "pkg:generic/project1",
          "name": "project1",
          "namespace": "generic",
          "provider": "any",
          "type": "project_file",
          "version": "128a63446a954579617e875aaab7d2978154e969",
          "details": {
            "type": "package",
            "permissions": null,
          "path": "project1.csproj"
          }
        }]
EOM


echo $STD_IN | jq --raw-output "$VAR"
