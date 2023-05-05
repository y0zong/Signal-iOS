#!/usr/bin/env python3

import os
import sys
import subprocess
import datetime
import argparse
import re
import json
import sds_common
from sds_common import fail
import tempfile
import shutil



# We need to generate fake -Swift.h bridging headers that declare the Swift
# types that our Objective-C files might use. This script does that.

def ows_getoutput(cmd):
    proc = subprocess.Popen(cmd,
        stdout = subprocess.PIPE,
        stderr = subprocess.PIPE,
    )
    stdout, stderr = proc.communicate()

    return proc.returncode, stdout, stderr


class Namespace:
    def __init__(self):
        self.swift_protocol_names = []
        self.swift_class_names = []


def parse_swift_ast(file_path, namespace, ast):
    json_data = json.loads(ast)

    json_maps = json_data.get('key.substructure')
    if json_maps is None:
        return

    for json_map in json_maps:
      kind = json_map.get('key.kind')
      if kind is None:
          continue
      elif kind == 'source.lang.swift.decl.protocol':
          # "key.kind" : "source.lang.swift.decl.protocol",
          # "key.length" : 1067,
          # "key.name" : "TypingIndicators",
          # "key.namelength" : 16,
          # "key.nameoffset" : 135,
          # "key.offset" : 126,
          # "key.runtime_name" : "OWSTypingIndicators",
          name = json_map.get('key.runtime_name')
          if name is None or len(name) < 1 or name.startswith('_'):
              name = json_map.get('key.name')
          if name is None or len(name) < 1:
              fail('protocol is missing name.')
              continue
          if name.startswith('_'):
              continue
          namespace.swift_protocol_names.append(name)
      elif kind == 'source.lang.swift.decl.class':
          # "key.kind" : "source.lang.swift.decl.class",
          # "key.length" : 15057,
          # "key.name" : "TypingIndicatorsImpl",
          # "key.namelength" : 20,
          # "key.nameoffset" : 1251,
          # "key.offset" : 1245,
          # "key.runtime_name" : "OWSTypingIndicatorsImpl",
          name = json_map.get('key.runtime_name')
          if name is None or len(name) < 1 or name.startswith('_'):
              name = json_map.get('key.name')
          if name is None or len(name) < 1:
              fail('class is missing name.')
              continue
          if name.startswith('_'):
              continue
          namespace.swift_class_names.append(name)


def process_file(file_path, namespace):
    filename = os.path.basename(file_path)
    if not filename.endswith('.swift'):
        return
    if filename == 'EmojiWithSkinTones+String.swift':
        return

    command = ['sourcekitten', 'structure', '--file', file_path]
    # for part in command:
    #     print '\t', part
    # command = ' '.join(command).strip()
    # print 'command', command
    # output = commands.getoutput(command)

    # command = ' '.join(command).strip()
    # print 'command', command
    exit_code, output, error_output = ows_getoutput(command)
    if exit_code != 0:
        print('exit_code:', exit_code)
        fail('Are you missing sourcekitten? Install with homebrew?')
    if len(error_output.strip()) > 0:
        print('error_output:', error_output)
    # print 'output:', len(output)

    # exit(1)

    output = output.strip()
    # print 'output', output

    parse_swift_ast(file_path, namespace, output)


def generate_swift_bridging_header(namespace, swift_bridging_path):

    output = []

    for name in namespace.swift_protocol_names:
        output.append('''
@protocol %s
@end
''' % ( name, ) )

    for name in namespace.swift_class_names:
        output.append('''
@interface %s : NSObject
@end
''' % ( name, ) )

    output = '\n'.join(output).strip()
    if len(output) < 1:
        return

    header = '''//
// Copyright 2022 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

#import <Foundation/Foundation.h>

// NOTE: This file is generated by %s.
// Do not manually edit it, instead run `sds_codegen.sh`.

''' % ( sds_common.pretty_module_path(__file__), )
    output = (header + output).strip()

    # print 'output:', output[:500]

    output = sds_common.clean_up_generated_swift(output)

    # print 'output:', output[:500]

    # print 'output', output

    parent_dir_path = os.path.dirname(swift_bridging_path)
    # print 'parent_dir_path', parent_dir_path
    if not os.path.exists(parent_dir_path):
        os.makedirs(parent_dir_path)

    print('Writing:', swift_bridging_path)
    with open(swift_bridging_path, 'wt') as f:
        f.write(output)


# ---

def process_dir(src_dir_path, dir_name, dst_dir_path):
    namespace = Namespace()

    dir_path = os.path.abspath(os.path.join(src_dir_path, dir_name))

    file_paths = []
    for rootdir, dirnames, filenames in os.walk(dir_path):
        for filename in filenames:
            file_path = os.path.abspath(os.path.join(rootdir, filename))
            file_paths.append(file_path)

    print(f"Found {len(file_paths)} files in {dir_path}")
    for (idx, file_path) in enumerate(file_paths):
        process_file(file_path, namespace)
        if idx % 100 == 99:
            print(f"... {idx+1} / {len(file_paths)}")

    bridging_header_path = os.path.abspath(os.path.join(dst_dir_path, dir_name, dir_name + '-Swift.h'))
    generate_swift_bridging_header(namespace, bridging_header_path)


# ---

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Parse Objective-C AST.')
    parser.add_argument('--src-path', required=True, help='used to specify a path to process.')
    parser.add_argument('--swift-bridging-path', required=True, help='used to specify a path to process.')
    args = parser.parse_args()

    src_dir_path = os.path.abspath(args.src_path)
    swift_bridging_path = os.path.abspath(args.swift_bridging_path)

    if os.path.exists(swift_bridging_path):
        shutil.rmtree(swift_bridging_path)

    # os.mkdir(swift_bridging_path)

    pods_dir_path = os.path.abspath(os.path.join(src_dir_path, 'Pods'))
    for dirname in os.listdir(pods_dir_path):
        if dirname.endswith('xcodeproj'):
            continue
        pod_dir_path = os.path.abspath(os.path.join(pods_dir_path, dirname))
        if not os.path.isdir(pod_dir_path):
            continue
        process_dir(pods_dir_path, dirname, swift_bridging_path)

    process_dir(src_dir_path, 'SignalServiceKit', swift_bridging_path)
    process_dir(src_dir_path, 'SignalMessaging', swift_bridging_path)
    process_dir(src_dir_path, 'Signal', swift_bridging_path)

