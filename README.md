# UnityBuiltinShaders

This is just the collected shaders from Unity versions 1.6.2 onward, expanded
and committed so you can see the evolution of the shaders over time.  For
versions prior to when everything was included in the zips available at
Unity's site, I have collected and included the relevant shaders from within
Unity.

I will continue to add new releases as they become available from various
locations, such as:

* [Official Release Archive](http://unity3d.com/unity/download/archive)
* [Patch Release Archive](http://unity3d.com/unity/qa/patch-releases)
* [4.6 Beta Site](http://unity3d.com/unity/beta/4.6)
* [5.0 Beta Site](http://unity3d.com/unity/beta/5.0)

## Tools

* `fetch.sh`: Tool to fetch all known versions of the built-in shaders from
  Unity3D.com.  Note that for versions prior to 4.1.0, some shaders were NOT
  included in the available zip file (specifically, the `CGIncludes/`
  directory) and had to be extracted from a Unity install!
* `ingest_release.sh`: Takes a version number with patch-level, and if the zip
  exists in `raw/`, will replace the working directory contents with it then
  commit them.  Will make an empty commit if nothing has changed.  It is your
  responsibility to ensure you are on the correct branch before running the
  script!
* `rebuild_history.sh`: A tool to help me rebuild the history in chronological
  order.  WARNING: Since I'm missing the zips for several releases, this
  involves cherry-picking existing commits very carefully!  Use with caution!

## Things to Know

1. Empty commits represent releases in which no shaders changed.
1. At present, the history of the repo is rather sloppy, and chronology and
   which releases are merged back into one another is not well represented.
1. I may rewrite the commit history at any point in order to better reflect the
   actual history of the shaders!  Be prepared for force-pushes!

## TODOs

* Identify version at which the bundled shaders were comprehensive and
  referring to a Unity install is no longer needed for completeness.
* Rewrite history to better reflect actual change history.
* Fill in a few missing releases:
    * 4.3.5XX through 4.3.7fX
    * 4.5.1p1 through 4.5.1p4
    * 4.5.2p1 through 4.5.2p3
    * 4.6.0b16 and below
    * 5.0.0b11
    * 5.0.0b12
