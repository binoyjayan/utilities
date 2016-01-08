
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
PAT=/local/mnt/workspace/src/patches
I=/local/mnt/workspace/images
T=/local/mnt/workspace/tmp
L=/local/mnt/workspace/logs
S=$HOME/scripts
SW=/local/mnt/workspace/software
KW=/local/mnt/workspace/software/KW
MK=/local/mnt/workspace/src/quic/ker/msm-3.18
RK=/local/mnt/workspace/src/quic/REPO/kernel
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
alias sw="cd $SW"
alias q="cd $Q"
alias i="cd $I"
alias lg="cd $L"

alias gs="git status"
alias gd="git diff"
alias ga="git add"
alias gc="git checkout"

alias gre="git rerere"
alias grs="git rerere status"
alias gl="git log"
alias gls="git ls-files -u"
alias gbr="git branch"
alias gbl="git blame -e"

alias gp="git push gerrit:kernel/msm HEAD:refs/for/LA.AF.1.1.1_kernel"

alias fd="sudo fastboot devices"
alias ad="sudo adb devices"
alias boot="sudo fastboot boot"
alias vo="vim -O"

alias abuild="source build/envsetup.sh ; lunch 12 ; make -j16"
alias aclean="source build/envsetup.sh ; lunch 12 ; make clean"
alias kbuilddep="source build/envsetup.sh ; lunch 12 ; make -j8 kernel"
alias kbuild="source build/envsetup.sh ; lunch 12 ; make ONE_SHOT_MAKEFILE=build/target/board/Android.mk bootimage"

alias pico="sudo picocom /dev/ttyUSB0 -b 115200 -l"

# alias minicom="echo Use picocom instead of /usr/bin/minicom. Remove alias in ~/scripts/cmds.sh"
# alias gls="git ls-files -u  | awk '{print $4}' | sort -u"
# alias grs="git rebase --skip"
# alias gra="git rebase --abort"
# alias gr="git rebase"
# alias grc="git rebase --continue"

