#!/usr/bin/python3

import click
import os
import sys

from config import *
from sfs import SFS

@click.group()
def cli():
    """
    A CLI tool to manage SFS File images.  These images can be raw copied over to an
    SDCARD for use on the 6502-Retro V3 Breadboard computer.

    Use: `./cli.py <CMD> --help` to learn more information about a specific command.
    """
    pass

@cli.command()
@click.option("-i", "--image", type=str, help="Path to local SDCARD image.", required=True)
def format(image):
    """
    Formats a new image.
    First create image with `dd if=/dev/zero of=sdcard.img count=40100 bs=512`
    """
    sfs = SFS(image)
    sfs.format()

@cli.command()
@click.option("-i", "--image", type=str, help="Path to local SDCARD image.", required=True)
@click.option("-s", "--source", type=str, help="The source. Either sfs://<filename> or ./<filename>", required=True)
@click.option("-d", "--destination", type=str, help="The destination. Either sfs://<filename> or ./<filename>", required=True)
def cp(image, source, destination):
    """
    Copies a file from SOURCE to DESTINATION.

    PATHS on the SFS Volume must be prefixed with sfs://
    LOCAL PATHS must be either full or relative paths.  Relies on python open() to access.
    """

    if source.startswith('sfs://'):
        if len(source) > 21:
            print(f'{source} must be less than 21 chars')
            sys.exit(1)
        else:
            sfs_filename = os.path.basename(source)
            copy_dir = 1        # FROM SFS TO LOCAL
            local_filename = destination
    elif destination.startswith('sfs://'):
        if len(destination) > 21:
            print(f'{source} must be less than 21 chars')
            sys.exit(1)
        else:
            sfs_filename = os.path.basename(destination)
            copy_dir = 0        # FROM LOCAL TO SFS
            local_filename = source
    else:
        print('Either source or destination must start with sfs://')
        sys.exit(1)
    
    print(f'COPYING {source} to {destination}')

    sfs = SFS(image)

    if copy_dir == 0:
        if sfs.create(sfs_filename):
            with open(local_filename, "rb") as fd:
                if sfs.write(fd.read()):
                    print(f'Wrote {sfs.idx.size} bytes...')
                else:
                    print('Could not save to SFS Image.  Was the file too large?')
                    sys.exit(2)
        else:
            print(f'Couldn not save {local_filename} to {image}')
            sys.exit(2)
    else:
        if sfs.find(sfs_filename):
            with open(local_filename, "wb") as fd:
                fd.write(sfs.read())
            print(f'Write {sfs.idx.size} bytes...')

@cli.command()
@click.option("-i", "--image", type=str, help="Path to local SDCARD image.", required=True)
def dir(image):
    """
    Lists files on the SCARD Image.
    """
    sfs = SFS(image)
    sfs.dir()

@cli.command()
@click.option("-i", "--image", type=str, help="Path to local SDCARD image.", required=True)
def new(image):
    """
    Creates a new SFS Disk <IMAGE> and formats it.
    
    The volume name is "SFS.DISK"
    """
    with open(image, 'wb') as fd:
        fd.write(b'\0' * 262400 * 512)
    sfs = SFS(image)
    sfs.format()

@cli.command()
@click.option("-i", "--image", type=str, help="Path to local SDCARD image.", required=True)
@click.option("-n", "--name", type=str, help="The file to delete.  sfs://<filename>", required=True)
def delete(image,name):
    """
    Deletes a file NAME from disk IMAGE.
    """
    if name.startswith('sfs://'):
        sfs_name = os.path.basename(name)
    else:
        print('NAME must start with sfs://')
        sys.exit(1)

    sfs = SFS(image)
    if sfs.find(sfs_name):
        sfs.unlink()
        print(f'Deleted {name}...')
    else:
        print(f'Could not find {name}')
        sys.exit(1)

if __name__ == "__main__":
    cli()
