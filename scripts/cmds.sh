
alias h="history"

alias gs="git status"
alias gd="git diff"
alias ga="git add"
alias gc="git checkout"
alias gsh="git show"
alias gco="git commit"
alias gca="git commit --amend"
alias gca2="git commit --amend --no-edit"
alias gcp="git cherry-pick"

alias gpf="git push --force"

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

alias pico="sudo picocom /dev/ttyUSB0 -b 115200 -l"
alias pico1="sudo picocom /dev/ttyUSB1 -b 115200 -l"
alias s3test="../test/s3cmd.sh"

# alias minicom="echo Use picocom instead of /usr/bin/minicom. Remove alias in ~/scripts/cmds.sh"
# alias gls="git ls-files -u  | awk '{print $4}' | sort -u"
# alias grs="git rebase --skip"
# alias gra="git rebase --abort"
# alias gr="git rebase"
# alias grc="git rebase --continue"

export LOGLEVEL=1
export BLD_TYPE=Debug
