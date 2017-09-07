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
import textwrap
import glob

DB_DIR='.patchdb'
DB_INF='db.inf'
DB_FILE='.patchdb/db.inf'
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

def load_file(filename, verbose):
    ret = True
    if not os.path.isfile(filename):
        print 'Patch database not found !'
        return False

    pr_debug(verbose, 'Reading patch database ' + filename)
    f = open(filename, 'r')
    if not f:
        print 'Failed to open patch database', filename
        return False

    if db_patches:
        pr_debug(verbose, 'Clearing old data...')
        db_patches.clear()

    pr_debug(verbose, 'Loading data...')

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

def db_is_empty():
    if not db_patches or len(db_patches) == 0:
        return True

    for db in db_patches:
        if db_patches[db] > 0:
            return False

    # If all repos have zero patches
    return True

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

def show_ps(ps, verbose):
    load_file(DB_FILE, verbose)
    disp_db()

def list_ps(patchset, verbose):
    pr_debug(verbose, 'Listing patchset ' + patchset)

    psetdir = DB_DIR + '/'+ patchset
    psetinf = DB_DIR + '/'+ patchset + '/' + DB_INF

    if not os.path.isdir(psetdir):
        print 'Patchset', patchset, 'not found in the database'
        return False

    if not os.path.isfile(psetinf):
        print 'Patch info [.inf] not found in the patchset'
        return False

    # Load the patchset
    load_file(psetinf, verbose)
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

        # Strip cwd from the absolute patch of the git repo
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

# List commits and prompt user to choose n
def get_num_patches(repo):
    # TODO
    return 1

def do_add_repo(repos, patches, verbose):
    i = 0
    for r in repos:
        # If #patch is mentioned for the repo
        if patches and i < len(patches):
            n = int(float(patches[i]))
        else:
            n = get_num_patches(r)

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

    load_file(DB_FILE, verbose)
    if do_add_repo(repos, patches, verbose):
        save_file()

def delete_repo(repos, force, verbose):
    if not force and not user_choice('Are you sure you want to delete the repos? (y/n):'):
        return False

    load_file(DB_FILE, verbose)
    do_delete_repo(repos, verbose)
    save_file()

def branch(br, verbose):
    load_file(DB_FILE, False)
    if not db_patches or len(db_patches) == 0:
	print 'Patch database is empty. There is no repo to branch'
        return

    cwd = os.getcwd()
    pr_debug(verbose, 'Running git branch' + br + 'for all repos in the database...')
    for db in db_patches:
        if not os.path.isdir(db + '/.git'):
            print 'Skipping', db, '; No git repo found !'
            continue
        os.chdir(db)
        if subprocess.call(['git', 'branch', br]):
            print 'Failed to create branch for', db
        os.chdir(cwd)

def checkout(br, verbose):
    load_file(DB_FILE, False)
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
        # print ['git', 'checkout', br]
        if subprocess.call(['git', 'checkout', br]):
            print 'Failed to checkout branch for', db
        os.chdir(cwd)

def generate(patchset, verbose):
    load_file(DB_FILE, False)
    if db_is_empty():
	print 'Patch database is empty. Add repos using -a'
        return False

    psetdir = DB_DIR + '/'+ patchset
    if os.path.isdir(psetdir):
        if not user_choice('Directory to generate patches is already present; Overwrite(y/n):'):
            return False
        pr_debug(verbose, 'Removing ' + psetdir)
        shutil.rmtree(psetdir)

    pr_debug(verbose, 'Creating patch export directory ' + psetdir)
    os.mkdir(psetdir)

    pr_debug(verbose, 'Creating patch sub-directories for individual repos')
    for db in db_patches:
        if db_patches[db] > 0:
            pr_debug(verbose, 'Creating ' + db)
            pdir = psetdir + '/' + db
            os.makedirs(pdir)
        else:
            pr_debug(verbose, 'Skipping ' + db)

    success = True
    pr_debug(verbose, 'Generating patches...')
    for db in db_patches:
        if db_patches[db] > 0:
            pdir = psetdir + '/' + db
            if not os.path.isdir(db + '/.git'):
                print 'Skipping', db, '; No git repo found !'
                success = False
                continue
            if subprocess.call(['git', '--git-dir=' + db + '/.git', 'format-patch', '-' + str(db_patches[db]), '-o', pdir]):
                print 'Failed to generate patches for', db
                success = False

    if success:
        print 'Generated patches at', psetdir, 'successfully'
        shutil.copy(DB_FILE, psetdir)
    else:
        print 'Failed to generate patches'

def revert(patchset, force, verbose):
    if not force and not user_choice('Are you sure you want to revert current patchset? (y/n):'):
        return False

    load_file(DB_FILE, False)
    if db_is_empty():
	print 'Patch database is empty. Nothing to revert'
        return

    cwd = os.getcwd()
    success = True
    pr_debug(verbose, 'Reverting patches...')
    for db in db_patches:
        if db_patches[db] > 0:
            if not os.path.isdir(db + '/.git'):
                print 'Skipping', db, '; No git repo found !'
                success = False
                continue
            os.chdir(db)
            if subprocess.call(['git', 'reset', '--hard', 'HEAD~' + str(db_patches[db])]):
                print 'Failed to revert patches for', db
                success = False
            else:
                db_patches[db] = 0
            os.chdir(cwd)

    save_file()

    if success:
        print 'Reverted all patches successfully'
    else:
        print 'Failed to revert one or more patches. Use asmpatch -s to view'

def apply_patches(gdir, pdir):
    filelist = glob.glob(pdir + '/*.patch')
    cwd = os.getcwd()
    n = 0
    success = True
    for fname in sorted(filelist):
        fullname = os.path.abspath(fname)
        os.chdir(gdir)
        pr_debug(verbose, 'Applying ' + fname)
        if subprocess.call(['git', 'am', fullname]):
            print 'Aborting', fname
            subprocess.call(['git', 'am', '--abort'])
            print 'Failed to apply a few patches; hence reverting', n
            subprocess.call(['git', 'reset', '--hard', 'HEAD~' + n])
            success = False
            break
        n = n + 1
        os.chdir(cwd)

    os.chdir(cwd)
    return success

def apply_ps(patchset, verbose):
    pr_debug(verbose, 'Applying patchset ' + patchset)
    load_file(DB_FILE, False)
    if not db_is_empty():
	print 'Patch database is not empty. Revert the patches before applying'
        return

    psetdir = DB_DIR + '/'+ patchset
    psetinf = DB_DIR + '/'+ patchset + '/' + DB_INF

    if not os.path.isdir(psetdir):
        print 'Patchset', patchset, 'not found in the database'
        return False

    if not os.path.isfile(psetinf):
        print 'Patch info [.inf] not found in the patchset'
        return False

    # Load the patchset
    load_file(psetinf, verbose)

    if db_is_empty():
	print 'Patch database is empty. No patches to apply'
        return False

    success = True
    pr_debug(verbose, 'Applying patches...')
    for db in db_patches:
        if db_patches[db] > 0:
            pdir = psetdir + '/' + db
            if not os.path.isdir(db + '/.git'):
                print 'Skipping', db, '; No git repo found !'
                success = False
                continue
            # TODO: Count patches and match against db
            success = apply_patches(db, pdir)
            if not success:
                db_patches[db] = 0

    save_file()

    if success:
        print 'Applied patchset', patchset, 'successfully'
    else:
        print 'Failed to apply patchset', psetdir
        print 'Please revert the partially applied patches using -r'

def import_ps(url, patchset, verbose):
    if not patchset:
        print 'Please mention the patchset to import by using -p'
        return False

    pr_debug(verbose, 'Importing patchset ' + patchset + ' from ' + url)
    host = None
    url = url.rstrip('/')
    arr = url.split(':')

    # Destination dir to copy patchset
    destdir = DB_DIR + '/' + patchset
    if os.path.isdir(destdir):
        if not user_choice('Patchset ' + patchset + ' already present; Overwrite(y/n):'):
            return False

        pr_debug(verbose, 'Removing older patchset...')
        shutil.rmtree(destdir)

    if len(arr) > 2:
        print 'Invalid url. url format: [ /path/to/repo | host:/path/to/repo ]'
        return False

    elif len(arr) == 2:
        host = arr[0]
        repo = arr[1]
        pr_debug(verbose, 'Importing ' + repo + ' from remote host ' + host)

        if subprocess.call(['scp', '-o', 'StrictHostKeyChecking no', '-r', url + '/' + DB_DIR + '/' + patchset, DB_DIR + '/']):
            print 'Failed to copy !'
            return False

    else:
        repo = arr[0]
        pr_debug(verbose, 'Importing ' + repo + ' from local host ')

        if not os.path.isdir(repo):
            print 'Local repo', repo, 'not found'
            return False

        pdir = repo + '/' + DB_DIR + '/' + patchset
        if not os.path.isdir(pdir):
            print pdir
            print 'Patchset', patchset, 'not found in the repo', repo
            return False

        if not os.path.isfile(pdir + '/' + DB_INF):
            print 'The patch info file [.inf] not found in the patchset', patchset
            return False

        pr_debug(verbose, 'Copying data... ')
        shutil.copytree(pdir, destdir)

    return True

# Helptext

helptext='''
Examples:

%(prog)s -s                show the current patch database
%(prog)s -a build/make     Add build/make to the patch database
%(prog)s -a bionic -n 2    Add bionic to patch db and mark two patches to be
                           taken from bionic
%(prog)s -a bionic -n 2 -a build/make -n 3
                           Add the repos with the respective # of patches each
%(prog)s -d bionic         Remove bionic from patch db
%(prog)s -g v1             Generate patches mentioned in patch db;
                           Name patchset as v1
%(prog)s -l v1             List the details of patchset v1
%(prog)s -p v1             Apply patches from the patchset named v1
                           from the patch database
%(prog)s -i repourl -p PS
                           Import patchset with name PS from
                           another android repo (local or remote):
                           local url  - /path/to/repo
                           remote url - hostname:/path/to/repo
%(prog)s -r                Revert patches in the current patch db

'''
# Description and version
parser = argparse.ArgumentParser(prog="asmpatch",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    description=textwrap.dedent('Patch Assembler 1.0'),
    epilog=helptext)

parser.add_argument('--version', action='version', version='%(prog)s 1.0')

# Define arguments
parser.add_argument('-a', '--add', metavar='DIR', action='append', help='Add a git repo to the patch database')
parser.add_argument('-d', '--delete', metavar='DIR', action='append', help='Delete a git repo from the patch database')
parser.add_argument('-n', '--patches', metavar='N', action='append', help='Number of patches to be prepared from the repo mentioned using --add [one per repo]')
parser.add_argument('-b', '--branch', metavar='NAME', help='Run git branch NAME for all repositories in the patch database')
parser.add_argument('-c', '--checkout', metavar='NAME', help='Run git checkout NAME for all the repositories in the patch database')
parser.add_argument('-g', '--generate', metavar='PS', help='Generate patchset for all repos [git format-patch] and store it the db with name PS')
parser.add_argument('-l', '--list', metavar='PS', help='List the details of patchset PS')
parser.add_argument('-p', '--apply', metavar='PS', help='Apply the patchset PS')
parser.add_argument('-i', '--import', metavar='REPO', help='Import patchset from another repo')
parser.add_argument('-s', '--show', action='store_true', help='Show details of the current patchset')
parser.add_argument('-r', '--revert', action='store_true', help='Revert patches in all the repos as mentioned in patch database')
parser.add_argument('-v', '--verbose', action='store_true', help='Turn on verbose mode')
parser.add_argument('-f', '--force', action='store_true', help='Force the current action')
args = vars(parser.parse_args())

verbose = False
force = False
if args['verbose']:
    verbose = True

if args['force']:
    force = True

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

if args['list']:
    list_ps(args['list'], verbose)
    sys.exit(0)

if args['revert']:
    revert(args['revert'], force, verbose)
    sys.exit(0)

if args['apply'] and not args['import']:
    apply_ps(args['apply'], verbose)
    sys.exit(0)

if args['import']:
    import_ps(args['import'], args['apply'], verbose)
    sys.exit(0)

if args['show']:
    show_ps(args['show'], verbose)
    sys.exit(0)

if args['add']:
    add_repo(args['add'], args['patches'], verbose)
    sys.exit(0)

if args['delete']:
    delete_repo(args['delete'], force, verbose)
    sys.exit(0)

