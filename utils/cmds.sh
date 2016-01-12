
TC1=/prj/l4linux/arm_compilers/arm32-linaro-compiler-4.8.2
TC2=/prj/l4linux/arm64-linaro-compiler/gcc-linaro-aarch64-linux-gnu-4.8-2013.09_linux
TC3=/pkg/asw/compilers/gnu/linaro-toolchain/.4.9-2014.06-02_linux-x86
TC=$TC1
L=/local/mnt
W=/local/mnt/workspace
Q=/local/mnt/workspace/src/quic
KO=/local/mnt/workspace/src/korg
LS=/local/mnt/workspace/src/korg/linux-stable
SRC=/local/mnt/workspace/src
HUB=/local/mnt/workspace/src/gh
XEN=/local/mnt/workspace/src/xen/setup
PAT=/local/mnt/workspace/src/patches
I=/local/mnt/workspace/images
T=/local/mnt/workspace/tmp
L=/local/mnt/workspace/logs
S=$HOME/scripts
SW=/local/mnt/workspace/software
KW=/local/mnt/workspace/software/KW
MK=/local/mnt/workspace/src/quic/ker/msm-3.10
GK=/local/mnt/workspace/src/google/msm
RK=/local/mnt/workspace/src/quic/REPO/kernel
M1=/local/mnt/workspace/src/quic/M1
M2=/local/mnt/workspace/src/quic/M2
R8996=/local/mnt/workspace/src/quic/8996/e

alias h="history"
alias tc="cd $TC"
alias tc1="cd $TC1"
alias tc2="cd $TC2"
alias lo="cd $L"
alias ws="cd $W"
alias kw="cd $KW"
alias sc="cd $S"
alias src="cd $SRC"
alias hub="cd $HUB"
alias x="cd $XEN"
alias sw="cd $SW"
alias q="cd $Q"
alias i="cd $I"
alias lg="cd $L"

alias gs="git status"
alias gd="git diff"
alias ga="git add"
alias gc="git checkout"
alias gsh="git show"
alias gco="git commit"
alias gca="git commit --amend"
alias gcp="git cherry-pick"

alias gre="git rerere"
alias grs="git rerere status"
alias gl="git log"
alias gls="git ls-files -u"
alias gbr="git branch"
alias gbl="git blame -e"

alias gp="git push"
alias gp1="git push gerrit:kernel/msm HEAD:refs/for/LA.AF.1.1.1_kernel"
alias gplk="git push gerrit:kernel/lk HEAD:refs/for/LNX.LA.2.7.3"
alias gp8960='git push gerrit:platform/vendor/qcom/msm8960 HEAD:refs/for/LA.AF.1.2.1'

alias chp="git format-patch -1 --stdout | ./scripts/checkpatch.pl - "
alias chplk="git format-patch -1 --stdout | $MK/scripts/checkpatch.pl - "

alias fd="sudo fastboot devices"
alias ad="sudo adb devices"
alias boot="sudo fastboot boot"
alias vo="vim -O"

alias abuild="source build/envsetup.sh ; lunch 12 ; make -j16"
alias aclean="source build/envsetup.sh ; lunch 12 ; make clean"
alias kbuilddep="source build/envsetup.sh ; lunch 12 ; make -j8 kernel"
alias kbuild="source build/envsetup.sh ; lunch 14 ; make ONE_SHOT_MAKEFILE=build/target/board/Android.mk bootimage"

alias CTS="cd /local/mnt/workspace/software/cts"

alias pico="sudo picocom /dev/ttyUSB0 -b 115200 -l"

# alias minicom="echo Use picocom instead of /usr/bin/minicom. Remove alias in ~/scripts/cmds.sh"
# alias gls="git ls-files -u  | awk '{print $4}' | sort -u"
# alias grs="git rebase --skip"
# alias gra="git rebase --abort"
# alias gr="git rebase"
# alias grc="git rebase --continue"

