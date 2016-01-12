#!/bin/bash

if [ -n "$1" -a -d "$1" ]
then
        echo "Reseting repo $1..."
	cd $IDIR
else
        echo "Mention REPO directory as argument"
	exit
fi

REPODIR=`readlink -m "$1"`

echo "Repo Directory: "

echo "Reset individual git repos...."
echo ""

echo "$REPODIR/cts"
cd $REPODIR/cts
git reset --hard
cd -

echo "$REPODIR/build/core"
cd $REPODIR/build/core
# git checkout main.mk
git reset --hard
cd -

echo "$REPODIR/device/qcom/common"
cd $REPODIR/device/qcom/common
# git checkout vendorsetup.sh
git reset --hard
cd -

echo "$REPODIR/device/qcom/msm8960"
cd $REPODIR/device/qcom/msm8960
# git checkout BoardConfig.mk
git reset --hard
cd -

echo "$REPODIR/device/qcom/msm8960"
cd $REPODIR/device/qcom/msm8960
# git checkout msm8960.mk
git reset --hard

echo "$REPODIR/vendor/qcom/opensource/wlan"
cd $REPODIR/vendor/qcom/opensource/wlan/qcacld-2.0
#git checkout Android.mk
git reset --hard

echo "$REPODIR/vendor/qcom/opensource/kernel-tests/watchdog"
cd $REPODIR/vendor/qcom/opensource/kernel-tests/watchdog
#git checkout Android.mk
git reset --hard

echo "$REPODIR/kernel"
cd $REPODIR/kernel
# git checkout quic/LA.AF.1.1.1_kernel
git reset --hard
cd -


