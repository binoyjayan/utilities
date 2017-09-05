#!/usr/bin/python

import os
import sys
import argparse

DB_DIR='.patchdb'
DB_FILE='.patchdb/db'
db_patches = {}

def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False

def load_file():
    ret = True
    if not os.path.isfile(DB_FILE):
        # print 'Patch database not found !'
        return False

    f = open(DB_FILE, 'r')
    if not f:
        print 'Failed to open patch database', DB_FILE
        return False

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
    if not db_patches:
	print 'Patch database is empty'
        return

    for db in db_patches:
        print db, ":", db_patches[db]

def save_file():
    if not os.path.isdir(DB_DIR):
        print 'Patch database not found ! Creating...'
        os.mkdir(directory)

    f = open(DB_FILE, 'w')
    if not f:
        print 'Failed to create the patch database !'
        return False

    print 'Writing values...'
    for db in db_patches:
        f.write('%s:%d\n' % (db, db_patches[db]))

    f.close()
    return True

def show_repos():
    load_file()
    disp_db()
    save_file()

def add_repo(repos, patches):
    print 'Adding repositories...'

def delete_repo(repos):
    print 'Deleting repositories...'

def generate():
    print 'Generating patches...'

def import_db(newdb):
    print 'Importing database from', newdb

# Description and version
parser = argparse.ArgumentParser(prog="asmpatch", description='Patch Assembler')
parser.add_argument('--version', action='version', version='%(prog)s 1.0')

# Define arguments
parser.add_argument('-s', '--show', metavar='DIR', action='append', help='Show the repositories present in the patch repository')
parser.add_argument('-a', '--add', metavar='DIR', action='append', help='Add a git repo to the patch database')
parser.add_argument('-d', '--delete', metavar='DIR', action='append', help='Delete a git repo from the patch database')
parser.add_argument('-n', '--patches', metavar='N', action='append', help='Number of patches to be prepared from the repo mentioned using --add')
parser.add_argument('-g', '--generate', metavar='DIR', help='Generate patches for all repos [git format-patch]')
parser.add_argument('-i', '--import', metavar='DB', help='Import patches from a patch database')
args = vars(parser.parse_args())

print 'ARGS:', args

if args['generate']:
    generate()
    sys.exit(0)

if args['import']:
    import_db(args['import'])
    sys.exit(0)

if args['show']:
    show_repos()
    sys.exit(0)

if args['add']:
    add_repo(args['add'], args['patches'])
    sys.exit(0)

if args['delete']:
    delete_repo(args['delete'])
    sys.exit(0)

