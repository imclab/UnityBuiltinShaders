#!/bin/bash

# See:
#   http://unity3d.com/unity/download/archive
#   http://unity3d.com/unity/qa/patch-releases
#   http://unity3d.com/unity/beta/4.6
#   http://unity3d.com/unity/beta/5.0

# TODO: Grab Samsung variants from:
# http://forum.unity3d.com/forums/samsung-smart-tv.66/
# http://forum.unity3d.com/threads/unity-for-samsung-smart-tv-public-preview.263343/
#   http://beta.unity3d.com/download/stv/unity-samsungtv-rc2.dmg
#   http://beta.unity3d.com/download/stv/unity-samsungtv-rc3.dmg
#   http://beta.unity3d.com/download/stv/unity-samsungtv-rc4.dmg

# Notes about which release versions the 4.6 beta versions line up against:
# * 4.6.0b17: (4.5.3f3 equivalency)
# * 4.6.0b18: (4.5.3f3 equivalency)
# * 4.5.4f1: (4.5.3p4 equivalency? includes patch from 4.5.3p3)
# * 4.6.0b19: (4.5.4f1 equivalency; includes patch from 4.5.3p3)
# * 4.6.0b20: (4.5.4f1 equivalency)
# * 4.6.0b21: (4.5.5f1 equivalency)
# * 4.6.0f1: (4.5.5f1 equivalency)
# * 4.6.0f2: (4.5.5f1 equivalency)

pushd raw
wget 'http://download.unity3d.com/download_unity/builtin_shaders-2.0.0.zip'     # Released: 2007-10-08
wget 'http://download.unity3d.com/download_unity/builtin_shaders-1.6.2.zip'     # Released: 2007-10-17
wget 'http://download.unity3d.com/download_unity/builtin_shaders-2.0.1.zip'     # Released: 2007-11-01

wget 'http://download.unity3d.com/download_unity/builtin_shaders-2.1.0.zip'     # Released: 2008-07-17

wget 'http://download.unity3d.com/download_unity/builtin_shaders-2.5.0.zip'     # Released: 2009-04-18
wget 'http://download.unity3d.com/download_unity/builtin_shaders-2.5.1.zip'     # Released: 2009-07-07
wget 'http://download.unity3d.com/download_unity/builtin_shaders-2.6.0.zip'     # Released: 2009-10-23
wget 'http://download.unity3d.com/download_unity/builtin_shaders-2.6.1.zip'     # Released: 2009-11-30

wget 'http://download.unity3d.com/download_unity/builtin_shaders-3.4.0.zip'     # Released: 2011-07-25
wget 'http://download.unity3d.com/download_unity/builtin_shaders-3.4.1.zip'     # Released: 2011-09-20
wget 'http://download.unity3d.com/download_unity/builtin_shaders-3.4.2.zip'     # Released: 2011-11-03

wget 'http://download.unity3d.com/download_unity/builtin_shaders-3.5.0.zip'     # Released: 2012-02-14
wget 'http://download.unity3d.com/download_unity/builtin_shaders-3.5.1.zip'     # Released: 2012-04-11
wget 'http://download.unity3d.com/download_unity/builtin_shaders-3.5.2.zip'     # Released: 2012-05-15
wget 'http://download.unity3d.com/download_unity/builtin_shaders-3.5.3.zip'     # Released: 2012-06-29
wget 'http://download.unity3d.com/download_unity/builtin_shaders-3.5.4.zip'     # Released: 2012-07-19
wget 'http://download.unity3d.com/download_unity/builtin_shaders-3.5.5.zip'     # Released: 2012-08-13
wget 'http://download.unity3d.com/download_unity/builtin_shaders-3.5.6.zip'     # Released: 2012-09-26
wget 'http://download.unity3d.com/download_unity/builtin_shaders-3.5.7.zip'     # Released: 2012-12-13
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.0.0.zip'     # Released: 2012-11-13

wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.0.1.zip'     # Released: 2013-01-11
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.1.0.zip'     # Released: 2013-03-13
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.1.1.zip'     # Released: 2013-03-21
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.1.2.zip'     # Released: 2013-03-25
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.1.3.zip'     # Released: 2013-05-22
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.1.4.zip'     # Released: 2013-06-06
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.1.5.zip'     # Released: 2013-06-08
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.2.0.zip'     # Released: 2013-07-21
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.2.1.zip'     # Released: 2013-09-02
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.2.2.zip'     # Released: 2013-10-10
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.3.0.zip'     # Released: 2013-11-11
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.3.1.zip'     # Released: 2013-11-28
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.3.2.zip'     # Released: 2013-12-17

wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.3.3.zip'     # Released: 2014-01-13
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.3.4.zip'     # Released: 2014-01-29
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.5.0.zip'     # Released: 2014-05-27
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.5.1.zip'     # Released: 2014-06-12
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.5.2.zip'     # Released: 2014-07-10
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.5.3.zip'     # Released: 2014-08-12
wget 'http://beta.unity3d.com/download/0360241441/builtin_shaders-4.5.3p1.zip'  # Released: 2014-08-14
wget 'http://beta.unity3d.com/download/0393862629/builtin_shaders-4.5.3p2.zip'  # Released: 2014-08-20
wget 'http://beta.unity3d.com/download/6541552447/builtin_shaders-4.5.3p3.zip'  # Released: 2014-08-28
wget 'http://beta.unity3d.com/download/7280546084/builtin_shaders-4.6.0b18.zip' # Released: 2014-08-28
wget 'http://beta.unity3d.com/download/9680176560/builtin_shaders-4.5.3p4.zip'  # Released: 2014-09-04
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.5.4.zip'     # Released: 2014-09-11
wget 'http://beta.unity3d.com/download/2305005142/builtin_shaders-4.3.7p4.zip'  # Released: 2014-09-17
wget 'http://beta.unity3d.com/download/3088431051/builtin_shaders-4.5.4p1.zip'  # Released: 2014-09-18
wget 'http://beta.unity3d.com/download/0987964749/builtin_shaders-4.6.0b19.zip' # Released: 2014-09-22
wget 'http://beta.unity3d.com/download/6685476520/builtin_shaders-4.5.4p2.zip'  # Released: 2014-09-26
wget 'http://netstorage.unity3d.com/unity/builtin_shaders-4.6.0b20.zip'         # Released: 2014-09-29
wget 'http://beta.unity3d.com/download/0293568922/builtin_shaders-4.5.4p3.zip'  # Released: 2014-10-03
wget 'http://download.unity3d.com/download_unity/builtin_shaders-4.5.5.zip'     # Released: 2014-10-13
wget 'http://beta.unity3d.com/download/4234258080/builtin_shaders-4.5.5p1.zip'  # Released: 2014-10-16
wget 'http://beta.unity3d.com/download/9029455969/builtin_shaders-4.6.0b21.zip' # Released: 2014-10-20
wget 'http://beta.unity3d.com/download/6523029087/builtin_shaders-4.5.5p2.zip'  # Released: 2014-10-23
wget 'http://netstorage.unity3d.com/unity/builtin_shaders-5.0.0b9.zip'          # Released: 2014-10-23
wget 'http://beta.unity3d.com/download/6568425883/builtin_shaders-4.5.5p3.zip'  # Released: 2014-10-30
wget 'http://beta.unity3d.com/download/7856424537/builtin_shaders-4.5.5p4.zip'  # Released: 2014-11-07
wget 'http://netstorage.unity3d.com/unity/builtin_shaders-4.6.0f1.zip'          # Released: 2014-11-07
wget 'http://beta.unity3d.com/download/3531360080/builtin_shaders-4.5.5p5.zip'  # Released: 2014-11-14
wget 'http://beta.unity3d.com/download/8238231711/builtin_shaders-5.0.0b13.zip' # Released: 2014-11-12
wget 'http://netstorage.unity3d.com/unity/builtin_shaders-4.6.0f2.zip'          # Released: 2014-11-13
popd
