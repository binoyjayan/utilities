#!/bin/bash
echo repo init -u git://git.quicinc.com/mdm/manifest.git -b LNX.LE.5.1
echo repo init -u git://git.quicinc.com/platform/manifest.git -b LA.AF.1.2.1 --repo-url=git://git.quicinc.com/tools/repo.git --repo-branch=caf/caf-stable
echo repo sync -j4 --no-tags -c -q

