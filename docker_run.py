#!/usr/bin/env python3

import os
import glob

from datetime import date
from multiprocessing import Pool
from os import path, environ
from zipfile import ZipFile, ZIP_DEFLATED


def patch_fonts(index, ttf_file):
    output_dir = environ.get('OUTPUT_DIR', '/output')
    log_file = f'{output_dir}/patch.{index}.log'
    command = (
        f'python3 font-patcher -c -q -w '
        f'-out "{output_dir}" "{ttf_file}" >>"{log_file}" 2>&1'
    )
    print('Run command:', command)
    os.system(command)
    print('Finish command:', command)


def main():
    build_dir = environ.get('BUILD_DIR', '/build')
    output_dir = environ.get('OUTPUT_DIR', '/output')

    ttf_dir = path.join(build_dir, 'Iosevka/dist/iosevka-custom/ttf')
    ttf_files = glob.glob(f'{ttf_dir}/*.ttf', recursive=True)

    with Pool(8) as pool:
        pool.starmap(patch_fonts, enumerate(ttf_files))

    today = date.today().strftime('%Y-%m-%d')
    zip_filename = f'{output_dir}/iosevka-custom-{today}.zip'

    print('Make archive:', zip_filename)
    with ZipFile(zip_filename, 'w', compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for filename in glob.glob(f'{output_dir}/*.ttf'):
            print(filename, '-->', zip_filename)
            archive.write(filename, path.basename(filename))


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('...')
        print('KeyboardInterrupt detected')
        exit(1)
