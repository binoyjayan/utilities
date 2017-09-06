#!/usr/bin/python
#
# Script to assemble the patches in various git repositories in an
# android repo. It can be used to quickly add, generate and export patches
# from one repo and import the same into another repo with ease.
#
# Binoy Jayan [ binoyjayan@gmail.com ]
#
import os
import sys
import shutil
import argparse
import subprocess

DB_DIR='.patchdb'
DB_FILE='.patchdb/db'
CWD = os.getcwd() + '/'
db_patches = {}

def pr_debug(verbose, s):
    if verbose:
        print s

def user_choice(s):
    choices = [ 'y', 'yes', 'n', 'no' ]
    ch = raw_input(s).lower()
    while ch not in choices:
        ch = raw_input('Invalid choice. Try again(y/n):').lower()

    if ch[0] == 'y':
        return True
    else:
        return False

def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False

def load_file(verbose):
    ret = True
    if not os.path.isfile(DB_FILE):
        pr_debug(verbose, 'Patch database not found !')
        return False

    f = open(DB_FILE, 'r')
    if not f:
        print 'Failed to open patch database', DB_FILE
        return False

    pr_debug(verbose, 'Loading patch info from database ' + DB_FILE)

    for line in iter(f.readline, ''):
        line = line.strip('\n').strip(' ')
        node = line.split(':')
        if not node or len(node) == 0 or (len(node) == 1 and node[0] == ""):
            continue

	if len(node) != 2:
            print 'Error reading db entry ' + line + ' len= ' + str(len(node))
            ret = False
            break

        s1 = node[0].strip(' ')
        s2 = node[1].strip(' ')
        if not is_number(s2):
            print "Invalid number of patches for repo " + node[0]
            ret = False
            break

        n = int(float(s2))
        db_patches[s1] = n

    f.close()

    return ret

def disp_db():
    if not db_patches or len(db_patches) == 0:
	print 'Patch database is empty. Add repos using -a'
        return

    #  Formatted display
    print '-' * 70
    print '{:55s} {:>10s}'.format('GIT REPO', '#PATCHES')
    print '-' * 70
    for db in db_patches:
        print '{:55s} {:>10d}'.format(db, db_patches[db])
    print '-' * 70

def save_file():
    if not os.path.isdir(DB_DIR):
        print 'Patch database not found ! Creating...'
        os.mkdir(DB_DIR)

    f = open(DB_FILE, 'w')
    if not f:
        print 'Failed to create the patch database !'
        return False

    print 'Updating database...'
    for db in db_patches:
        f.write('%s:%d\n' % (db, db_patches[db]))

    f.close()
    return True

def show_repos(verbose):
    load_file(verbose)
    disp_db()

def validate(repos, patches, verbose):
    # repos is always non-null when we are here
    if patches and len(repos) < len(patches):
        print 'The per-repo patches exceeds the repositories mentioned'
        return False

    valid = True

    i = 0
    for r in repos:
        t = os.path.abspath(r)
        pr_debug(verbose, 'FULL PATH: ' + t)
        if not t or not os.path.isdir(t):
            print 'Repo not found:', r
            valid = False
            continue

        r = t.replace(CWD, '')
        pr_debug(verbose, 'STRIPPED PATH: ' + r)
        if r[0] == '/' or not os.path.isdir(r):
            print 'The git repo', r, 'is not part of the current project'
            continue

        if not os.path.isdir(r + '/.git'):
            print 'The directory', r, ' is not a git repository'
            valid = False
            continue

        # Modify the repo name stripped of '/' and of absolute path
        repos[i] = r
        i = i + 1

    if patches:
        for p in patches:
            if not is_number(p) or int(float(p)) < 0:
                print 'Invalid number of patches', p
                valid = False

    return valid

def do_add_repo(repos, patches, verbose):
    i = 0
    for r in repos:
        # If #patch is mentioned for the repo
        if patches and i < len(patches):
            n = int(float(patches[i]))
        else:
            n = 1

        if r in db_patches.keys():
            if not user_choice('Repo ' + r + ' already present in the db; Overwrite(y/n):'):
                return False

        pr_debug(verbose, 'Adding repo ' + str(r) + ' with ' + str(n) + ' patch(es)')
        db_patches[r] = n
        i =  i + 1
        return True

def do_delete_repo(repos, verbose):
    for r in repos:
        if r in db_patches.keys():
            pr_debug(verbose, 'Removing repo ' + r)
            del db_patches[r]
            return True

        t = r.strip('/')
        if t in db_patches.keys():
            pr_debug(verbose, 'Removing repo ' + t)
            del db_patches[t]
            return True

        print 'Repo', r, 'not found in the database'

def add_repo(repos, patches, verbose):
    if not validate(repos, patches, verbose):
        return False

    load_file(verbose)
    if do_add_repo(repos, patches, verbose):
        save_file()

def delete_repo(repos, verbose):
    load_file(verbose)
    do_delete_repo(repos, verbose)
    save_file()

def branch(br, verbose):
    load_file(False)
    if not db_patches or len(db_patches) == 0:
	print 'Patch database is empty. There is no repo to branch'
        return

    pr_debug(verbose, 'Running git branch' + br + 'for all repos in the database...')
    for db in db_patches:
        if not os.path.isdir(db + '/.git'):
            print 'Skipping', db, '; No git repo found !'
            continue
        if subprocess.call(['git', '--git-dir=' + db + '/.git', 'branch', br]):
            print 'Failed to create branch for', db

def checkout(br, verbose):
    load_file(False)
    if not db_patches or len(db_patches) == 0:
	print 'Patch database is empty. There is no repo to checkout'
        return

    cwd = os.getcwd()
    pr_debug(verbose, 'Running git checkout' + br + 'for all repos in the database...')
    for db in db_patches:
        if not os.path.isdir(db + '/.git'):
            print 'Skipping', db, '; No git repo found !'
            continue
        # checkout operation has to be done from inside the git repo
        os.chdir(db)
        # print ['git', 'checkout', '-b', br]
        if subprocess.call(['git', 'checkout', '-b', br]):
            print 'Failed to checkout branch for', db
        os.chdir(cwd)

def generate(outdir, verbose):
    load_file(False)
    if not db_patches or len(db_patches) == 0:
	print 'Patch database is empty. Add repos using -a'
        return

    pdir = DB_DIR + '/'+ outdir
    if os.path.isdir(pdir):
        if not user_choice('Directory to generate patches is already present; Overwrite(y/n):'):
            return False
        pr_debug(verbose, 'Removing ' + pdir)
        shutil.rmtree(pdir)

    pr_debug(verbose, 'Creating patch export directory ' + pdir)
    os.mkdir(pdir)

    pr_debug(verbose, 'Creating patch sub-directories for individual repos')
    for db in db_patches:
        if db_patches[db] > 0:
            pr_debug(verbose, 'Creating ' + db)
            subdir = pdir + '/' + db
            os.makedirs(subdir)
        else:
            pr_debug(verbose, 'Skipping ' + db)

    success = True
    pr_debug(verbose, 'Generating patches...')
    for db in db_patches:
        if db_patches[db] > 0:
            subdir = pdir + '/' + db
            if not os.path.isdir(db + '/.git'):
                print 'Skipping', db, '; No git repo found !'
                success = False
                continue
            if subprocess.call(['git', '--git-dir=' + db + '/.git', 'format-patch', '-' + str(db_patches[db]), '-o', subdir]):
                print 'Failed to generate patches for', db
                success = False

    if success:
        print 'Generated patches at', pdir, 'successfully'
    else:
        print 'Failed to generate patches'

def revert(outdir, verbose):
    load_file(False)
    if not db_patches or len(db_patches) == 0:
	print 'Patch database is empty. Nothing to revert'
        return

    success = True
    pr_debug(verbose, 'Reverting patches...')
    for db in db_patches:
        if db_patches[db] > 0:
            if not os.path.isdir(db + '/.git'):
                print 'Skipping', db, '; No git repo found !'
                success = False
                continue
            if subprocess.call(['git', '--git-dir=' + db + '/.git', 'reset', '--hard', 'HEAD~' + str(db_patches[db]) ]):
                print 'Failed to revert patches for', db
                success = False
            else:
                db_patches[db] = 0

    save_file()

    if success:
        print 'Reverted all patches successfully'
    else:
        print 'Failed to revert one or more patches. Use asmpatch -s to view'

def import_db(newdb):
    print 'Importing database from', newdb

# Description and version
parser = argparse.ArgumentParser(prog="asmpatch", description='Patch Assembler 1.0', epilog='Cheers, Binoy')
parser.add_argument('--version', action='version', version='%(prog)s 1.0')

# Define arguments
parser.add_argument('-a', '--add', metavar='DIR', action='append', help='Add a git repo to the patch database')
parser.add_argument('-d', '--delete', metavar='DIR', action='append', help='Delete a git repo from the patch database')
parser.add_argument('-n', '--patches', metavar='N', action='append', help='Number of patches to be prepared from the repo mentioned using --add [one per repo]')
parser.add_argument('-b', '--branch', metavar='NAME', help='Run git branch NAME for all repositories in the patch database')
parser.add_argument('-c', '--checkout', metavar='NAME', help='Run git checkout -b NAME for all the repositories in the patch database')
parser.add_argument('-g', '--generate', metavar='NAME', help='Generate patches for all repos [git format-patch]')
parser.add_argument('-i', '--import', metavar='DB', help='Import patches from a patch database')
parser.add_argument('-r', '--revert', action='store_true', help='Revert patches in all the repos as mentioned in patch database')
parser.add_argument('-s', '--show', action='store_true', help='Show the repositories present in the patch repository')
parser.add_argument('-v', '--verbose', action='store_true', help='Turn on verbose mode')
parser.add_argument('-f', '--force', action='store_true', help='Force the current action')
args = vars(parser.parse_args())

verbose = False
if args['verbose']:
    verbose = True

pr_debug(verbose, 'ARGS:' + str(args))

if args['branch']:
    branch(args['branch'], verbose)
    sys.exit(0)

if args['checkout']:
    checkout(args['checkout'], verbose)
    sys.exit(0)

if args['generate']:
    generate(args['generate'], verbose)
    sys.exit(0)

if args['revert']:
    revert(args['revert'], verbose)
    sys.exit(0)

if args['import']:
    import_db(args['import'])
    sys.exit(0)

if args['show']:
    show_repos(verbose)
    sys.exit(0)

if args['add']:
    add_repo(args['add'], args['patches'], verbose)
    sys.exit(0)

if args['delete']:
    delete_repo(args['delete'], verbose)
    sys.exit(0)

