#
# Usage: deploy [-ns] root branch_name
#
#   -n = Ignore branch check
#   -s = Simulate the process
#


# OPTIONS


ignore_branch_check=0
simulate=0

while getopts "ns" opt; do
  case $opt in
    n) ignore_branch_check=1;;
    s) simulate=1 ;;
    *) exit 1 ;;
  esac
done
shift "$(( OPTIND - 1 ))"


# ARGS


root="${1:?}"
branch_name="${2:?}"


# MAIN


if ((simulate)); then
  echo "ATTENTION!!! This is only a simulation"
  set -x
fi

# CHECK BRANCH

current_branch="$(git branch --show-current)"
if ! ((ignore_branch_check)); then
  if [ "$current_branch" != master ]; then
    echo "You are currently on the branch: $current_branch"
    #
    # NOTE:
    #
    # Usually you'd want to deploy from the master branch. On rare
    # occassions you'd deploy from another branch. So deploying
    # from a different branch could be a mistake and that's why we
    # verify if you want to continue with the deploy.
    #
    read -r -n 1 -t 30 -p "Are you sure want to continue? (y/N) "
    case $REPLY in
      y | Y ) echo ;;
      * ) exit 1 ;;
    esac
  fi
fi

# PREPARE DEPLOY DIRECTORY

out="$(mktemp -d -t deploy-XXXXX)"
echo "Prepared the deploy directory: $out"

# PREPARE WORKTREE

if ! ((simulate)); then
  # Refresh remote-tracking branches and remove stale ones
  git fetch origin --prune

  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    # Local branch exists: check it out and bring it up to date
    git worktree add "$out" "$branch_name"
    # Update the worktree only if it can fast-forward; never create a merge commit
    git -C "$out" pull --ff-only

  elif git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
    # Only the remote branch exists: create a local tracking branch from it
    git worktree add --track -b "$branch_name" "$out" "origin/$branch_name"

  else
    # First deploy: create a new orphan branch with no existing history
    git worktree add --orphan -b "$branch_name" "$out"
  fi
fi

# DEPLOY

hash="$(git log -n 1 --format='%h' "$current_branch")"
message="Site updated to commit $hash from the $current_branch branch"

rsync -rtvz --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r --progress --delete --exclude=".git" "$root/" "$out"
#
# --recursive, -r   = recurse into directories
# --times, -t       = preserve modification times
# --verbose, -v     = increase verbosity
# --compress, -z    = compress file data during the transfer
# --chmod           = set permissions of directories and files
# --progress        = show progress during transfer
# --delete          = delete extraneous files from dest dirs
# --exclude=PATTERN = exclude files matching PATTERN
#

if ((simulate)); then
  echo "message=$message"
else
  git -C "$out" add .

  if git -C "$out" diff --cached --quiet; then
    echo "No changes detected"
  else
    git -C "$out" commit -m "$message"
    git -C "$out" push -u origin HEAD
  fi
fi

# CLEAN UP

if ((simulate)); then
  echo "Please run \"rm -rf $out\" when you're done"
else
  git worktree remove --force "$out"
  rm -rf "$out"

  echo "Success!"
fi
