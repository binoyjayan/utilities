#!/usr/bin/env python

import os,sys,subprocess

def exec_cmd(cmd, args):
    cmd.extend(args)
    # print cmd
    stdout = None
    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, \
                                stderr=subprocess.PIPE)
        stdout,stderr = proc.communicate()
        returncode = proc.poll()
        if returncode:
            # print "Command ", cmd , "returns ", returncode
            return None
    except:
        e = sys.exc_info()[1]
        print "Error: %s" % e
	return None

    return stdout

def validate_commit(cid):
    if not os.path.isdir(".git"):
        print "Current directory is not a git repository"
        sys.exit(1)

    commit = exec_cmd(['git', 'log', '-n', '1'], cid)

    if commit == None:
        print "The commit ID", cid, " seems to be an invalid one"
        sys.exit(2)

    idx1 = commit.find("Git-commit:");
    if idx1 == -1:
        print "Error: Git-commit tag not found in commit message."
        sys.exit(3)

    idx2 = commit.find("Git-repo:");
    if idx2 == -1:
        print "Error: Git-repo tag not found in commit message."
        sys.exit(4)

    edx1 = commit.find("\n", idx1);
    edx2 = commit.find("\n", idx2);

    print "Git commit =", commit[idx1+12: edx1]
    print "Git repo   =", commit[idx2+10: edx2]
    return commit

# main
commit = validate_commit(sys.argv[1:])
# print commit[:-1]
