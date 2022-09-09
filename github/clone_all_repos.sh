#!/bin/bash
set -u

################################################################################
# Grab the list of all the repos from an organization
# and clone it using git clone (ssh based)
################################################################################


################################################################################
# Input variables, set those as environment variables
################################################################################

#GHTOKEN="<Replace by you GH app token>"
# To list private repos, enable repos acces to your access token
#See https://github.com/settings/tokens

#URL="https://api.github.com/orgs/containerd/repos"
#URL="https://api.github.com/orgs/containerd/repos"
#URL=https://api.github.com/orgs/containerd/repos\?per_page=90\&q=archived%3Afalse


################################################################################

#Working files
HEADER_OUT=header.out
PAYLOAD_OUT=payload.out
REPOS_OUT=repo.list


#GRAB the organization ID from Response header
HEADERS=(-H "Accept: application/vnd.github+json")
HEADERS+=(-H "Authorization: token $GHTOKEN")

[ -f $REPOS_OUT ] && rm $REPOS_OUT


#Inspired from https://gist.github.com/tsukhu/d5b1594b7b79e5e228e5d28f255a82b2
PAGE=0
NEXT_PAGE_URL=$URL

while true; do
  let PAGE++

  echo "Getting page ${PAGE}"
  curl -sL "${HEADERS[@]}" -o $PAYLOAD_OUT -D $HEADER_OUT $NEXT_PAGE_URL
  #Parse git repo url (ssh)
  jq -r '.. | .ssh_url? //empty' $PAYLOAD_OUT >> $REPOS_OUT

  #Parse next page url from header
  #Inspired from https://michaelheap.com/follow-github-link-header-bash/
  OLD_PAGE_URL=$NEXT_PAGE_URL
  NEXT_PAGE_URL=`sed -n -E 's/link:.*<(.*?)>; rel="next".*/\1/p' $HEADER_OUT`

  #IF empty, this was the last page
  [ -z "$NEXT_PAGE_URL" ] && break

done

COUNT=`cat $REPOS_OUT | wc -l`
echo "Repossitory count: $COUNT"


echo Cloning the repos

REPO_LIST=`cat $REPOS_OUT`

i=0
for repo in $REPO_LIST
do
 let i++
 echo " **  Cloning the repository ($i/$COUNT)"
 git clone $repo

done
