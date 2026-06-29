● #!/bin/sh
FOLDERS="dotfiles eclipse-workspace work"


  find_git_repos() {
      folder="$1"
      find "$folder" -type d -name ".git" 2>/dev/null | while read gitdir; do
          repo=$(dirname "$gitdir")
          echo "=== $repo ==="
          git -C "$repo" status
          echo ""
      done
  }

  for folder in $FOLDERS; do
      if [ ! -d "$folder" ]; then
          echo "=== $folder (directory not found) ==="
          continue
      fi
      find_git_repos "$folder"
  done