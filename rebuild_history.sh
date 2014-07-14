#!/bin/bash

ON_434=$(($(git log --oneline -1 HEAD | grep 4.3.4 | wc -l) + 0))
V451_P1=$(git rev-list --oneline --all | grep 4.5.1p1 | head -1 | cut -d' ' -f1)
V451_P2=$(git rev-list --oneline --all | grep 4.5.1p2 | head -1 | cut -d' ' -f1)
V451_P3=$(git rev-list --oneline --all | grep 4.5.1p3 | head -1 | cut -d' ' -f1)
V451_P4=$(git rev-list --oneline --all | grep 4.5.1p4 | head -1 | cut -d' ' -f1)
V452_P1=$(git rev-list --oneline --all | grep 4.5.2p1 | head -1 | cut -d' ' -f1)
V452_P2=$(git rev-list --oneline --all | grep 4.5.2p2 | head -1 | cut -d' ' -f1)
V452_P3=$(git rev-list --oneline --all | grep 4.5.2p3 | head -1 | cut -d' ' -f1)

if [ $ON_434 -ne 1 ]; then
  echo "Must be on commit representing version 4.3.4."
  exit 1
fi

if [ "$V451_P1" == "" ]; then
  echo "Can't find commit for 4.5.4p1."
  exit 1
fi

if [ "$V451_P2" == "" ]; then
  echo "Can't find commit for 4.5.4p2."
  exit 1
fi

if [ "$V451_P3" == "" ]; then
  echo "Can't find commit for 4.5.4p3."
  exit 1
fi

if [ "$V451_P4" == "" ]; then
  echo "Can't find commit for 4.5.4p4."
  exit 1
fi

if [ "$V452_P1" == "" ]; then
  echo "Can't find commit for 4.5.2p1."
  exit 1
fi

if [ "$V452_P2" == "" ]; then
  echo "Can't find commit for 4.5.2p2."
  exit 1
fi

if [ "$V452_P3" == "" ]; then
  echo "Can't find commit for 4.5.2p3."
  exit 1
fi

REV_434_COMMIT=$(git rev-list -1 HEAD)
git branch --force release $REV_434_COMMIT
git checkout release
./ingest_release.sh 4.5.0     # Released: 2014-05-27
git checkout -b maintenance/4.5.1
./ingest_release.sh 4.5.1     # Released: 2014-06-12
git cherry-pick --allow-empty $V451_P1
git cherry-pick --allow-empty $V451_P2
git cherry-pick --allow-empty $V451_P3
git cherry-pick --allow-empty $V451_P4
git checkout release
git checkout -b maintenance/4.5.2
./ingest_release.sh 4.5.2     # Released: 2014-07-10
git cherry-pick --allow-empty $V452_P1
git cherry-pick --allow-empty $V452_P2
git cherry-pick --allow-empty $V452_P3
git checkout release
git checkout -b maintenance/4.5.3
./ingest_release.sh 4.5.3     # Released: 2014-08-12
./ingest_release.sh 4.5.3p1   # Released: 2014-08-14
./ingest_release.sh 4.5.3p2   # Released: 2014-08-20
./ingest_release.sh 4.5.3p3   # Released: 2014-08-28
git checkout -b maintenance/4.6.0
./ingest_release.sh 4.6.0b18  # Released: 2014-08-28
git checkout maintenance/4.5.3
./ingest_release.sh 4.5.3p4   # Released: 2014-09-04
git checkout -b maintenance/4.5.4
./ingest_release.sh 4.5.4     # Released: 2014-09-11
git branch --force maintenance/4.3.7 $REV_434_COMMIT
git checkout maintenance/4.3.7
./ingest_release.sh 4.3.7p4   # Released: 2014-09-17
git checkout maintenance/4.5.4
./ingest_release.sh 4.5.4p1   # Released: 2014-09-18
git checkout maintenance/4.6.0
./ingest_release.sh 4.6.0b19  # Released: 2014-09-22
git checkout -b maintenance/5.0.0
git checkout maintenance/4.5.4
./ingest_release.sh 4.5.4p2   # Released: 2014-09-26
git checkout maintenance/4.6.0
./ingest_release.sh 4.6.0b20  # Released: 2014-09-29
git checkout maintenance/4.5.4
./ingest_release.sh 4.5.4p3   # Released: 2014-10-03
git checkout -b maintenance/4.5.5
./ingest_release.sh 4.5.5     # Released: 2014-10-13
git branch -f release
git branch dummy_4.5.5
./ingest_release.sh 4.5.5p1   # Released: 2014-10-16
git checkout maintenance/4.6.0
git merge dummy_4.5.5 -m "Bring in upstream changes."
git branch -d dummy_4.5.5
./ingest_release.sh 4.6.0b21  # Released: 2014-10-20
git checkout maintenance/4.5.5
./ingest_release.sh 4.5.5p2   # Released: 2014-10-23
git checkout maintenance/5.0.0
./ingest_release.sh 5.0.0b9   # Released: 2014-10-23
git checkout maintenance/4.5.5
./ingest_release.sh 4.5.5p3   # Released: 2014-10-30
./ingest_release.sh 4.5.5p4   # Released: 2014-11-07
git checkout maintenance/4.6.0
./ingest_release.sh 4.6.0f1   # Released: 2014-11-07
git checkout maintenance/4.5.5
./ingest_release.sh 4.5.5p5   # Released: 2014-11-14
git checkout maintenance/5.0.0
./ingest_release.sh 5.0.0b13  # Released: 2014-11-12
git branch next HEAD
git checkout maintenance/4.6.0
./ingest_release.sh 4.6.0f2   # Released: 2014-11-13
git branch -f master HEAD

echo
echo "Validating history against upstreams.  Should see no output, or minimal output if making corrections to history."
echo
git diff maintenance/4.5.1..origin/maintenance/4.5.1 -- CGIncludes/ DefaultResources/ DefaultResourcesExtra/ Editor/
git diff maintenance/4.5.2..origin/maintenance/4.5.2 -- CGIncludes/ DefaultResources/ DefaultResourcesExtra/ Editor/
git diff maintenance/4.5.3..origin/maintenance/4.5.3 -- CGIncludes/ DefaultResources/ DefaultResourcesExtra/ Editor/
git diff maintenance/4.5.4..origin/maintenance/4.5.4 -- CGIncludes/ DefaultResources/ DefaultResourcesExtra/ Editor/
git diff maintenance/4.5.5..origin/maintenance/4.5.5 -- CGIncludes/ DefaultResources/ DefaultResourcesExtra/ Editor/
git diff maintenance/4.6.0..origin/master -- CGIncludes/ DefaultResources/ DefaultResourcesExtra/ Editor/
git diff maintenance/5.0.0..origin/next -- CGIncludes/ DefaultResources/ DefaultResourcesExtra/ Editor/
git diff master..origin/master -- CGIncludes/ DefaultResources/ DefaultResourcesExtra/ Editor/
git diff next..origin/next -- CGIncludes/ DefaultResources/ DefaultResourcesExtra/ Editor/
